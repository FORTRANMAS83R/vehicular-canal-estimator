% filepath: c:\code\liu\vehicular-canal-estimator\src\simulation\emitter\generate_signal.m
%
% generate_signal - Generates a modulated or unmodulated signal segment for simulation.
%
% Syntax:
%   signal = generate_signal(i, type_modulation, params, T_boucle)
%
% Description:
%   This function generates a modulated or unmodulated (pure carrier) signal for a given time interval.
%   The output is a structure containing the waveform, time vector, and relevant modulation parameters.
%   Supported modulations: 'bpsk', 'qpsk', 'qam16', 'qam64', and 'sans_modulation' (pure carrier).
%
% Inputs:
%   i               : Integer, time interval index (for time offset)
%   type_modulation : String, modulation type ('bpsk', 'qpsk', 'qam16', 'qam64', 'sans_modulation')
%   params          : Struct with fields:
%                       - sps : Samples per symbol (oversampling factor)
%                       - fc  : Carrier frequency (Hz)
%                       - fs  : Sampling frequency (Hz)
%   T_boucle        : Duration of the signal segment (seconds)
%
% Outputs:
%   signal : Struct with fields:
%       - time     : Time vector for the segment
%       - waveform : Complex baseband waveform (column vector)
%       - symbols  : Modulated symbols (empty for 'sans_modulation')
%       - bits     : Transmitted bits (empty for 'sans_modulation')
%       - fs       : Sampling frequency (Hz)
%       - fc       : Carrier frequency (Hz)
%       - type     : Modulation type (string)
%       - sps      : Samples per symbol
%
% Notes:
%   - For 'sans_modulation', the function generates a pure carrier (complex exponential).
%   - For modulated signals, random bits are generated and mapped to symbols.
%   - Pulse shaping is performed using a root-raised cosine filter.
%   - The output structure is consistent for all modulation types.
%
% Author: Mikael Franco
%

function signal = generate_signal(i, type_modulation, params, T_boucle)
% Number of samples to generate for the segment
Nsamples = round(T_boucle * params.fs);
t = (0:Nsamples-1)/params.fs + i*T_boucle;

if strcmpi(type_modulation, 'sans_modulation')
    % Generate a pure carrier (unmodulated signal)
    f0 = params.fc; % Carrier frequency
    tx_rf = exp(1j*2*pi*f0*t); % Complex carrier
    signal.time     = t;
    signal.waveform = tx_rf(:); % Column vector
    signal.symbols  = [];
    signal.bits     = [];
    signal.fs       = params.fs;
    signal.fc       = params.fc;
    signal.type     = type_modulation;
    signal.sps      = params.sps;
    return;
end

% Number of symbols to generate
Nb_symbols = ceil(Nsamples / params.sps);
k = log2(get_modulation_order(type_modulation));
Nb_bits = Nb_symbols * k;

% Generate random bits and map to symbols
bits = randi([0 1], Nb_bits, 1);

switch lower(type_modulation)
    case 'bpsk'
        symbols = pskmod(bits, 2);
    case 'qpsk'
        symbols = pskmod(bits, 4, pi/4, 'gray');
    case '16qam'
        symbols = qammod(bits, 16, 'InputType', 'bit', 'UnitAveragePower', true);
    case '64qam'
        symbols = qammod(bits, 64, 'InputType', 'bit', 'UnitAveragePower', true);
    otherwise
        error('Unknown modulation type. Choose among: ''bpsk'', ''qpsk'', ''qam16'', ''qam64'', ''sans_modulation''.');
end

% Pulse shaping (root-raised cosine)
rrc = rcosdesign(0.35, 4, params.sps);
tx_waveform = upfirdn(symbols, rrc, params.sps);

% Truncate or zero-pad to the correct length
if length(tx_waveform) > Nsamples
    tx_waveform = tx_waveform(1:Nsamples);
else
    tx_waveform = [tx_waveform; zeros(Nsamples - length(tx_waveform), 1)];
end

% Local time vector for this interval
Ts = 1 / params.fs;
t = (0:Nsamples-1) * Ts + i * T_boucle;

% RF modulation (carrier)
tx_rf = tx_waveform .* exp(1j * 2 * pi * params.fc * t.');

% Output structure
signal.time     = t;
signal.waveform = tx_rf;
signal.symbols  = symbols;
signal.bits     = bits;
signal.fs       = params.fs;
signal.fc       = params.fc;
signal.type     = type_modulation;
signal.sps      = params.sps;
end
