clear; clc; close all;
a = 1;
n = 7; 
l = 2;  
m = 0;   

%box size
Rmax = 3 * n^2 * a;

Ncoarse = 40;
r_c     = linspace(0, Rmax, Ncoarse);
theta_c = linspace(0, pi, Ncoarse);
phi_c   = linspace(0, 2*pi, Ncoarse);
[Rg, THg, PHg] = ndgrid(r_c, theta_c, phi_c);
psi_c = hydrogenWavefunction(n, l, m, Rg, THg, PHg, a);
max_density = max(abs(psi_c(:)).^2) * 1.2;  

%rejection sampling in Cartesian coordinates
Ntarget = 8000;   
accepted_x = []; accepted_y = []; accepted_z = []; accepted_density = [];
batch = 20000;
while length(accepted_x) < Ntarget
    x = (2*rand(batch,1)-1) * Rmax;
    y = (2*rand(batch,1)-1) * Rmax;
    z = (2*rand(batch,1)-1) * Rmax;
    r = sqrt(x.^2 + y.^2 + z.^2);
    r(r==0) = eps;
    theta = acos(z ./ r);
    phi = atan2(y, x);
    phi(phi < 0) = phi(phi < 0) + 2*pi;
    psi = hydrogenWavefunction(n, l, m, r, theta, phi, a);
    density = abs(psi).^2;
    accept = rand(batch,1) < (density / max_density);
    accepted_x = [accepted_x; x(accept)];
    accepted_y = [accepted_y; y(accept)];
    accepted_z = [accepted_z; z(accept)];
    accepted_density = [accepted_density; density(accept)];  
end
accepted_x = accepted_x(1:Ntarget);
accepted_y = accepted_y(1:Ntarget);
accepted_z = accepted_z(1:Ntarget);
accepted_density = accepted_density(1:Ntarget); 

% normalize density to [0,1] 
d_norm = (accepted_density - min(accepted_density)) / ...
         (max(accepted_density) - min(accepted_density) + eps);

%% Figure 1: 3D cloud with sweeping 
% phi_sweep = 0   -> full sphere
% phi_sweep = 360 -> entire sphere cut away

phi_sweep = 0;   % degrees

phi_accepted = atan2(accepted_y, accepted_x);
phi_accepted(phi_accepted < 0) = phi_accepted(phi_accepted < 0) + 2*pi;

% remove the wedge 
keep = phi_accepted > deg2rad(phi_sweep);

vx = accepted_x(keep);
vy = accepted_y(keep);
vz = accepted_z(keep);
vd = d_norm(keep);

figure('Color','k');                      
s = scatter3(vx, vy, vz, 6, vd, 'filled');
s.MarkerFaceAlpha = 'flat';
s.AlphaData = 0.15 + 0.55*vd;       
colormap(summer);                         
axis equal;
ax = gca;
ax.Color = 'k';
ax.XColor = [0.5 0.5 0.5];
ax.YColor = [0.5 0.5 0.5];
ax.ZColor = [0.5 0.5 0.5];
xlabel('x','Color','w'); ylabel('y','Color','w'); zlabel('z','Color','w');
title(sprintf('Electron probability cloud (\\phi cut: %.0f°): n=%d, l=%d, m=%d', phi_sweep, n, l, m), 'Color','w');
grid on;
ax.GridColor = [0.3 0.3 0.3];
view(45, 25);

%%  Numerical validation: radial node count 
theta0 = pi/3;
phi0   = pi/4;

r_scan = linspace(0.01, Rmax, 3000);   
psi_scan = hydrogenWavefunction(n, l, m, r_scan, theta0*ones(size(r_scan)), phi0*ones(size(r_scan)), a);
R_proxy = abs(psi_scan);              

d1 = diff(R_proxy);
is_min = [false, (d1(1:end-1) < 0 & d1(2:end) > 0), false];
min_idx = find(is_min);

threshold = 0.02 * max(R_proxy);
node_idx = min_idx(R_proxy(min_idx) < threshold);
node_count_numeric = numel(node_idx);

node_count_theory = n - l - 1;

fprintf('--- Radial node check ---\n');
fprintf('Theoretical nodes (n-l-1): %d\n', node_count_theory);
fprintf('Numerically detected nodes: %d\n', node_count_numeric);

%%  Numerical validation: average electron distance 
accepted_r = sqrt(accepted_x.^2 + accepted_y.^2 + accepted_z.^2);
r_mean_numeric = mean(accepted_r);
r_mean_theory  = (a/2) * (3*n^2 - l*(l+1));

percent_error = 100 * abs(r_mean_numeric - r_mean_theory) / r_mean_theory;

fprintf('\n--- <r> check ---\n');
fprintf('Theoretical <r>: %.4f\n', r_mean_theory);
fprintf('Numerical <r> (from sampled points): %.4f\n', r_mean_numeric);
fprintf('Percent error: %.2f%%\n', percent_error);

%% Figure 2: Radial probability density |R_nl(r)|^2 
R_density = R_proxy.^2;

figure('Color','w');
plot(r_scan, R_density, 'LineWidth', 2, 'Color', [0.3 0.3 0.75]);
hold on;
if ~isempty(node_idx)
    plot(r_scan(node_idx), R_density(node_idx), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
    legend('|R_{nl}(r)|^2', 'Nodes', 'Location', 'best');
end
xlabel('r (units of a_0)');
ylabel('|R_{nl}(r)|^2');
title(sprintf('Radial probability density: n=%d, l=%d, m=%d', n, l, m));
grid on;
hold off;

%%  Figure 3: Radial probability distribution P(r) = |R_nl(r)|^2 * r^2 
P_r = R_density .* r_scan.^2;
P_r = P_r / trapz(r_scan, P_r);

figure('Color','w');
plot(r_scan, P_r, 'LineWidth', 2, 'Color', [0.2 0.6 0.2]);
hold on;
if ~isempty(node_idx)
    plot(r_scan(node_idx), P_r(node_idx), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
    legend('P(r)', 'Nodes', 'Location', 'best');
end
xlabel('r (units of a_0)');
ylabel('P(r)');
title(sprintf('Radial probability distribution: n=%d, l=%d, m=%d', n, l, m));
grid on;

annotation_text = sprintf('Theoretical nodes (n-l-1): %d\nDetected nodes: %d\n<r> theory: %.3f\n<r> numeric: %.3f (%.2f%% error)', ...
    node_count_theory, node_count_numeric, r_mean_theory, r_mean_numeric, percent_error);
text(0.55*Rmax, 0.85*max(P_r), annotation_text, ...
    'FontSize', 9, 'BackgroundColor', [1 1 0.9], 'EdgeColor', [0.5 0.5 0.5], 'Margin', 6);
hold off;

%%  Figure 4: Monte Carlo convergence study
N_list = round(logspace(2, log10(Ntarget), 12));
r_mean_vs_N = zeros(size(N_list));

for k = 1:length(N_list)
    Nk = N_list(k);
    r_mean_vs_N(k) = mean(accepted_r(1:Nk));
end

error_vs_N = abs(r_mean_vs_N - r_mean_theory);

figure('Color','w');
loglog(N_list, error_vs_N, 'o-', 'LineWidth', 2, 'MarkerSize', 6, 'Color', [0.2 0.4 0.7]);
hold on;
ref_line = error_vs_N(1) * sqrt(N_list(1) ./ N_list);
loglog(N_list, ref_line, '--', 'LineWidth', 1.5, 'Color', [0.6 0.6 0.6]);
hold off;
xlabel('Number of samples N');
ylabel('Error in <r>');
title(sprintf('Monte Carlo convergence: n=%d, l=%d, m=%d', n, l, m));
legend('Numerical error', 'Theoretical 1/\surdN trend', 'Location', 'best');
grid on;

%% 3D surface of revolution
persistent_fig_name = 'OrbitalRadialSurfaceViewer';
existing_fig = findall(0, 'Type', 'figure', 'Name', persistent_fig_name);
if isempty(existing_fig)
    fig = uifigure('Name', persistent_fig_name, 'Position', [100 100 700 550]);
    tgroup = uitabgroup(fig, 'Position', [0 0 700 550]);
else
    fig = existing_fig(1);
    tgroup = findall(fig, 'Type', 'uitabgroup');
end
tab_title = sprintf('n=%d, l=%d', n, l);
new_tab = uitab(tgroup, 'Title', tab_title);
ax3 = uiaxes(new_tab, 'Position', [20 20 660 500]);
theta_rev = linspace(0, 2*pi, 60);
[Rr, Th] = meshgrid(r_scan, theta_rev);
Zdensity = interp1(r_scan, R_density, Rr(1,:), 'linear', 'extrap');
Zdensity = repmat(Zdensity, length(theta_rev), 1);
X_rev = Rr .* cos(Th);
Y_rev = Rr .* sin(Th);
z_scale = 0.4 * Rmax / max(Zdensity(:));
Z_rev = Zdensity * z_scale;
surf(ax3, X_rev, Y_rev, Z_rev, Zdensity, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
colormap(ax3, turbo);
cb = colorbar(ax3);
cb.Label.String = 'Probability density';
shading(ax3, 'interp');
camlight(ax3);
lighting(ax3, 'gouraud');
axis(ax3, 'vis3d');
axis(ax3, 'off');
view(ax3, 30, 25);
title(ax3, sprintf('Radial probability density profile: n=%d, l=%d', n, l));
tgroup.SelectedTab = new_tab;