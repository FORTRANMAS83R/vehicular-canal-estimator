function signal = generate_signal(i, type_modulation, params, T_boucle)
% Génére un signal modulé pour un intervalle temporel indexé par i
% - i              : indice temporel
% - type_modulation: 'bpsk', 'qpsk', 'qam16', 'qam64'
% - params         : struct avec champs :
%       .sps : samples per symbol (oversampling)
%       .fc  : fréquence porteuse (Hz)
%       .fs  : fréquence d'échantillonnage (Hz)
% - T_boucle       : durée temporelle d’un segment (s)

% 1. Nombre d’échantillons à générer sur la fenêtre

Nsamples = round(T_boucle * params.fs);

% 2. Nombre de symboles à générer
Nb_symbols = ceil(Nsamples / params.sps);
k = log2(get_modulation_order(type_modulation));
Nb_bits = Nb_symbols * k;

% 3. Génération des bits et mapping en symboles
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
        error('Modulation inconnue. Choisir parmi : ''bpsk'', ''qpsk'', ''qam16'', ''qam64''.');
end

% 4. Mise en forme (pulse shaping)
rrc = rcosdesign(0.35, 4, params.sps);
tx_waveform = upfirdn(symbols, rrc, params.sps);

% 5. Tronquer ou ajuster à la bonne taille
if length(tx_waveform) > Nsamples
    tx_waveform = tx_waveform(1:Nsamples);
else
    tx_waveform = [tx_waveform; zeros(Nsamples - length(tx_waveform), 1)];
end

% 6. Temps local à l’intervalle i
Ts = 1 / params.fs;
t = (0:Nsamples-1) * Ts + i * T_boucle;

% 7. Modulation RF (porteuse)
tx_rf = tx_waveform .* exp(1j * 2 * pi * params.fc * t.');

% 8. Struct de sortie
signal.time     = t;
signal.waveform = tx_rf;
signal.symbols  = symbols;
signal.bits     = bits;
signal.fs       = params.fs;
signal.fc       = params.fc;
signal.type     = type_modulation;
signal.sps      = params.sps;
end
