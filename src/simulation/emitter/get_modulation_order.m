function M = get_modulation_order(type)
    switch lower(type)
        case 'bpsk'
            M = 2;
        case 'qpsk'
            M = 4;
        case '16qam'
            M = 16;
        case '64qam'
            M = 64;
        % Ajoute d’autres cas si nécessaire
        otherwise
            error('Modulation type "%s" not recognized.', type);
    end
end