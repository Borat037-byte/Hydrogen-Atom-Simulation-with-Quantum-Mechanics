function R = radialWavefunction(n, l, r, a)
    % Input validation
    if n < 1 || floor(n) ~= n
        error('n must be a positive integer.');
    end
    if floor(l) ~= l
        error('l must be an integer.');
    end
    if l < 0 || l > n-1
        error('Quantum numbers must satisfy 0 <= l <= n-1.');
    end

    m = n + l;
    q = 2*l + 1;

    %Griffiths convention
    
    L_prev = 1;
    L_curr = [-1 1];

    if m == 0
        L = L_prev;
    elseif m == 1
        L = L_curr;
    else
        for k = 1:m-1
            xL_curr    = [L_curr 0];
            L_curr_pad = [0 L_curr];
            L_prev_pad = [0 0 L_prev];
            L = ((2*k+1)*L_curr_pad - xL_curr - k*L_prev_pad)/(k+1);
            L_prev = L_curr;
            L_curr = L;
            % L_curr_pad = [ 0 -1  1]
            % xL_curr    = [-1  1  0]
            % L_prev_pad = [ 0  0  1]
        end
    end

    L = factorial(m) * L;   

    Lq = L;
    for i = 1:q
        Lq = polyder(Lq);
    end

    Lq = ((-1)^q) * Lq;

    rho = 2*r/(n*a);

    Lval = polyval(Lq, rho);

    N = sqrt( (2/(n*a))^3 * factorial(n-l-1) / (2*n*(factorial(n+l))^3) );

    R = N .* (rho.^l) .* exp(-rho/2) .* Lval;

end