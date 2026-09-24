function psi = hydrogenWavefunction(n, l, m, r, theta, phi, a)
    R = radialWavefunction(n, l, r, a);
    Y = angularWavefunction(l, m, theta, phi);
    psi = R .* Y;
end