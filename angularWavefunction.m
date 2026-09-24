function Y = angularWavefunction(l, m, theta, phi)

    if abs(m) > l || l < 0 || floor(l) ~= l
        error('value of l invalid')
    end

    sz = size(theta);
    x = cos(theta(:))';        % flatten theta to a row vector before calling legendre
    P = legendre(l, x);

    row = abs(m) + 1;
    P = P(row, :);

    if m < 0
        P = ((-1)^abs(m)) * (factorial(l-abs(m))/factorial(l+abs(m))) * P;
    end

    P = reshape(P, sz);        % restore original shape before combining with phi

    N = sqrt((2*l+1)/(4*pi) * factorial(l-m)/factorial(l+m));

    Y = N .* P .* exp(1i*m*phi);

end

    