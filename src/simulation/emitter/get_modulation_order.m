function M = get_modulation_order(type)
    % GET_MODULATION_ORDER Returns the modulation order (M) for a given modulation type.
    %
    % Syntax:
    %   M = get_modulation_order(type)
    %
    % Description:
    %   This function returns the modulation order M (number of symbols) corresponding to the specified
    %   modulation type. Supported types are: 'bpsk', 'qpsk', '16qam', and '64qam'.
    %
    % Inputs:
    %   type : String
    %       Modulation type ('bpsk', 'qpsk', '16qam', '64qam')
    %
    % Outputs:
    %   M : Integer
    %       Modulation order (2 for BPSK, 4 for QPSK, 16 for 16QAM, 64 for 64QAM)
    %
    % Notes:
    %   - The function is case-insensitive.
    %   - An error is thrown if the modulation type is not recognized.
    %
    % Author: Mikael Franco
    %
    switch lower(type)
        case 'bpsk'
            M = 2;
        case 'qpsk'
            M = 4;
        case '16qam'
            M = 16;
        case '64qam'
            M = 64;
        otherwise
            error('Modulation type "%s" not recognized.', type);
    end
end