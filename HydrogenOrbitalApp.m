classdef HydrogenOrbitalApp < matlab.apps.AppBase

    properties (Access = public)
        UIFigure          matlab.ui.Figure
        nSpinner          matlab.ui.control.Spinner
        lSpinner          matlab.ui.control.Spinner
        mSpinner          matlab.ui.control.Spinner
        AngleSlider       matlab.ui.control.Slider
        AngleValueLabel   matlab.ui.control.Label
        ResetButton       matlab.ui.control.Button
        SimulateButton    matlab.ui.control.Button
        ValidationText    matlab.ui.control.TextArea
        CloudAxes         matlab.ui.control.UIAxes
        SurfaceAxes       matlab.ui.control.UIAxes
        ConvergenceAxes   matlab.ui.control.UIAxes
        DensityAxes       matlab.ui.control.UIAxes
        DistributionAxes  matlab.ui.control.UIAxes
        SurfaceColorbar
    end

    properties (Access = private)
        a = 1;
        Ntarget = 8000;
        accepted_x; accepted_y; accepted_z; d_norm; accepted_r;
        r_scan; R_density; node_idx; node_count_theory; node_count_numeric;
        r_mean_theory; r_mean_numeric; percent_error;
        Rmax;
    end

    methods (Access = private)

        function createComponents(app)
            appBG = [0.82 0.85 0.88];
            panelBG = [0.94 0.95 0.96];
            headerBG = [0.75 0.80 0.86];

            app.UIFigure = uifigure('Name', 'Hydrogen Atom Orbital Simulator', ...
                'Position', [100 100 1400 780], 'Color', appBG);

            mainGrid = uigridlayout(app.UIFigure, [1 2]);
            mainGrid.ColumnWidth = {330, '1x'};
            mainGrid.ColumnSpacing = 15;
            mainGrid.Padding = [10 10 10 10];

            % ---------- LEFT SIDEBAR ----------
            sidePanel = uipanel(mainGrid, 'BackgroundColor', panelBG, ...
                'BorderType', 'line', 'HighlightColor', [0.5 0.5 0.5]);
            sidePanel.Layout.Column = 1;

            sideGrid = uigridlayout(sidePanel, [7 1]);
            sideGrid.RowHeight = {32, 45, 32, 55, 25, 40, 150};
            sideGrid.Padding = [12 12 12 12];
            sideGrid.RowSpacing = 8;

            lbl1 = uilabel(sideGrid, 'Text', 'Quantum Numbers', 'FontWeight', 'bold', ...
                'FontColor', [0.1 0.1 0.1], 'BackgroundColor', headerBG, ...
                'HorizontalAlignment', 'center', 'FontSize', 13);
            lbl1.Layout.Row = 1;

            qnGrid = uigridlayout(sideGrid, [1 6]);
            qnGrid.Layout.Row = 2;
            qnGrid.ColumnWidth = {15,62,15,62,15,62};
            qnGrid.ColumnSpacing = 4;
            qnGrid.Padding = [0 0 0 0];
            uilabel(qnGrid, 'Text', 'n', 'FontColor','k', 'HorizontalAlignment','center');
            app.nSpinner = uispinner(qnGrid, 'Limits', [1 6], 'Value', 4, 'RoundFractionalValues', 'on');
            uilabel(qnGrid, 'Text', 'l', 'FontColor','k', 'HorizontalAlignment','center');
            app.lSpinner = uispinner(qnGrid, 'Limits', [0 5], 'Value', 1, 'RoundFractionalValues', 'on');
            uilabel(qnGrid, 'Text', 'm', 'FontColor','k', 'HorizontalAlignment','center');
            app.mSpinner = uispinner(qnGrid, 'Limits', [-5 5], 'Value', 0, 'RoundFractionalValues', 'on');

            lbl2 = uilabel(sideGrid, 'Text', 'Cutting Angle (\phi)', 'Interpreter','tex', ...
                'FontWeight','bold', 'FontColor', [0.1 0.1 0.1], 'BackgroundColor', headerBG, ...
                'HorizontalAlignment', 'center', 'FontSize', 13);
            lbl2.Layout.Row = 3;

            app.AngleSlider = uislider(sideGrid, 'Limits', [0 180], 'Value', 0, ...
                'MajorTicks', 0:30:180);
            app.AngleSlider.Layout.Row = 4;
            app.AngleSlider.ValueChangingFcn = @(s,e) app.onAngleChanging(e);

            app.AngleValueLabel = uilabel(sideGrid, 'Text', '0°', 'FontColor','k', ...
                'BackgroundColor', panelBG, 'HorizontalAlignment', 'center', ...
                'FontWeight', 'bold', 'FontSize', 13);
            app.AngleValueLabel.Layout.Row = 5;

            btnGrid = uigridlayout(sideGrid, [1 2]);
            btnGrid.Layout.Row = 6;
            btnGrid.ColumnSpacing = 10;
            btnGrid.Padding = [0 0 0 0];
            app.ResetButton = uibutton(btnGrid, 'Text', 'Reset', ...
                'BackgroundColor', [0.85 0.55 0.55], 'FontColor', 'k', ...
                'FontWeight', 'bold', 'ButtonPushedFcn', @(b,e) app.onReset());
            app.SimulateButton = uibutton(btnGrid, 'Text', 'Simulate', ...
                'BackgroundColor', [0.55 0.75 0.55], 'FontColor', 'k', ...
                'FontWeight', 'bold', 'ButtonPushedFcn', @(b,e) app.onSimulate());

            app.ValidationText = uitextarea(sideGrid, 'Editable', 'off', ...
                'Value', {'Validation results will appear here after Simulate.'}, ...
                'FontColor', 'k', 'BackgroundColor', [0.98 0.98 0.98]);
            app.ValidationText.Layout.Row = 7;

            % ---------- RIGHT: PLOTS AREA ----------
            plotGrid = uigridlayout(mainGrid, [2 2]);
            plotGrid.Layout.Column = 2;
            plotGrid.RowHeight = {'1x','1x'};
            plotGrid.ColumnWidth = {'2x','1x'};
            plotGrid.RowSpacing = 12;
            plotGrid.ColumnSpacing = 12;

            % --- Left plot column: cloud + surface viewer ---
            leftPlotGrid = uigridlayout(plotGrid, [2 1]);
            leftPlotGrid.Layout.Row = [1 2];
            leftPlotGrid.Layout.Column = 1;
            leftPlotGrid.RowSpacing = 12;
            leftPlotGrid.Padding = [0 0 0 0];

            cloudPanel = uipanel(leftPlotGrid, 'BackgroundColor', panelBG, 'BorderType', 'line');
            cloudPanel.Layout.Row = 1;
            cloudGrid = uigridlayout(cloudPanel, [1 1]);
            cloudGrid.Padding = [8 8 8 8];
            app.CloudAxes = uiaxes(cloudGrid);

            surfacePanel = uipanel(leftPlotGrid, 'BackgroundColor', panelBG, 'BorderType', 'line');
            surfacePanel.Layout.Row = 2;
            surfaceGrid = uigridlayout(surfacePanel, [1 1]);
            surfaceGrid.Padding = [8 8 8 8];
            app.SurfaceAxes = uiaxes(surfaceGrid);

            % --- Right plot column: convergence, density, distribution ---
            rightPlotGrid = uigridlayout(plotGrid, [3 1]);
            rightPlotGrid.Layout.Row = [1 2];
            rightPlotGrid.Layout.Column = 2;
            rightPlotGrid.RowSpacing = 12;
            rightPlotGrid.Padding = [0 0 0 0];

            convPanel = uipanel(rightPlotGrid, 'BackgroundColor', panelBG, 'BorderType', 'line');
            convPanel.Layout.Row = 1;
            convGrid = uigridlayout(convPanel, [1 1]);
            convGrid.Padding = [8 8 8 8];
            app.ConvergenceAxes = uiaxes(convGrid);

            densPanel = uipanel(rightPlotGrid, 'BackgroundColor', panelBG, 'BorderType', 'line');
            densPanel.Layout.Row = 2;
            densGrid = uigridlayout(densPanel, [1 1]);
            densGrid.Padding = [8 8 8 8];
            app.DensityAxes = uiaxes(densGrid);

            distPanel = uipanel(rightPlotGrid, 'BackgroundColor', panelBG, 'BorderType', 'line');
            distPanel.Layout.Row = 3;
            distGrid = uigridlayout(distPanel, [1 1]);
            distGrid.Padding = [8 8 8 8];
            app.DistributionAxes = uiaxes(distGrid);
        end

        function onAngleChanging(app, event)
            app.AngleValueLabel.Text = sprintf('%.0f°', event.Value);
            app.refreshCloudOnly(event.Value);
        end

        function onReset(app)
            app.nSpinner.Value = 1;
            app.lSpinner.Value = 0;
            app.mSpinner.Value = 0;
            app.AngleSlider.Value = 0;
            app.AngleValueLabel.Text = '0°';
            cla(app.CloudAxes); cla(app.SurfaceAxes); cla(app.ConvergenceAxes);
            cla(app.DensityAxes); cla(app.DistributionAxes);
            app.ValidationText.Value = {'Validation results will appear here after Simulate.'};
        end

        function onSimulate(app)
            n = app.nSpinner.Value;
            l = app.lSpinner.Value;
            m = app.mSpinner.Value;

            if l > n-1
                app.ValidationText.Value = {sprintf('Invalid: l must be <= n-1 (n=%d, l max=%d)', n, n-1)};
                return;
            end
            if abs(m) > l
                app.ValidationText.Value = {sprintf('Invalid: m must satisfy |m| <= l (l=%d)', l)};
                return;
            end

            app.Rmax = 3 * n^2 * app.a;
            app.runSampling(n, l, m);
            app.runValidation(n, l, m);
            app.refreshCloudOnly(app.AngleSlider.Value);
            app.plotSurfaceViewer(n, l);
            app.plotConvergence();
            app.plotDensityAndDistribution(n, l, m);

            app.ValidationText.Value = {
                sprintf('--- Radial node check ---')
                sprintf('Theoretical nodes (n-l-1): %d', app.node_count_theory)
                sprintf('Detected nodes: %d', app.node_count_numeric)
                sprintf('')
                sprintf('--- <r> check ---')
                sprintf('Theoretical <r>: %.4f', app.r_mean_theory)
                sprintf('Numerical <r>: %.4f', app.r_mean_numeric)
                sprintf('Percent error: %.2f%%', app.percent_error)
                };
        end

        function runSampling(app, n, l, m)
            Ncoarse = 40;
            r_c = linspace(0, app.Rmax, Ncoarse);
            theta_c = linspace(0, pi, Ncoarse);
            phi_c = linspace(0, 2*pi, Ncoarse);
            [Rg, THg, PHg] = ndgrid(r_c, theta_c, phi_c);
            psi_c = hydrogenWavefunction(n, l, m, Rg, THg, PHg, app.a);
            max_density = max(abs(psi_c(:)).^2) * 1.2;

            ax_ = []; ay_ = []; az_ = []; ad_ = [];
            batch = 20000;
            while length(ax_) < app.Ntarget
                x = (2*rand(batch,1)-1) * app.Rmax;
                y = (2*rand(batch,1)-1) * app.Rmax;
                z = (2*rand(batch,1)-1) * app.Rmax;
                r = sqrt(x.^2 + y.^2 + z.^2);
                r(r==0) = eps;
                theta = acos(z ./ r);
                phi = atan2(y, x);
                phi(phi < 0) = phi(phi < 0) + 2*pi;
                psi = hydrogenWavefunction(n, l, m, r, theta, phi, app.a);
                density = abs(psi).^2;
                accept = rand(batch,1) < (density / max_density);
                ax_ = [ax_; x(accept)]; ay_ = [ay_; y(accept)];
                az_ = [az_; z(accept)]; ad_ = [ad_; density(accept)];
            end
            app.accepted_x = ax_(1:app.Ntarget);
            app.accepted_y = ay_(1:app.Ntarget);
            app.accepted_z = az_(1:app.Ntarget);
            accepted_density = ad_(1:app.Ntarget);
            app.d_norm = (accepted_density - min(accepted_density)) / ...
                (max(accepted_density) - min(accepted_density) + eps);
            app.accepted_r = sqrt(app.accepted_x.^2 + app.accepted_y.^2 + app.accepted_z.^2);
        end

        function refreshCloudOnly(app, phi_sweep_deg)
            if isempty(app.accepted_x)
                return;
            end
            phi_acc = atan2(app.accepted_y, app.accepted_x);
            phi_acc(phi_acc < 0) = phi_acc(phi_acc < 0) + 2*pi;
            keep = phi_acc > deg2rad(phi_sweep_deg);

            cla(app.CloudAxes);
            s = scatter3(app.CloudAxes, app.accepted_x(keep), app.accepted_y(keep), ...
                app.accepted_z(keep), 6, app.d_norm(keep), 'filled');
            s.MarkerFaceAlpha = 'flat';
            s.AlphaData = 0.15 + 0.55*app.d_norm(keep);
            colormap(app.CloudAxes, summer);
            axis(app.CloudAxes, 'equal');
            app.CloudAxes.Color = 'k';
            app.CloudAxes.XColor = [0.6 0.6 0.6];
            app.CloudAxes.YColor = [0.6 0.6 0.6];
            app.CloudAxes.ZColor = [0.6 0.6 0.6];
            title(app.CloudAxes, sprintf('Electron probability cloud (\\phi cut: %.0f°)', phi_sweep_deg), ...
                'Color', 'k', 'Interpreter', 'tex');
            grid(app.CloudAxes, 'on');
            app.CloudAxes.GridColor = [0.4 0.4 0.4];
            view(app.CloudAxes, 45, 25);
        end

        function runValidation(app, n, l, m)
            theta0 = pi/3; phi0 = pi/4;
            app.r_scan = linspace(0.01, app.Rmax, 3000);
            psi_scan = hydrogenWavefunction(n, l, m, app.r_scan, theta0*ones(size(app.r_scan)), ...
                phi0*ones(size(app.r_scan)), app.a);
            R_proxy = abs(psi_scan);
            app.R_density = R_proxy.^2;

            d1 = diff(R_proxy);
            is_min = [false, (d1(1:end-1) < 0 & d1(2:end) > 0), false];
            min_idx = find(is_min);
            threshold = 0.02 * max(R_proxy);
            app.node_idx = min_idx(R_proxy(min_idx) < threshold);
            app.node_count_numeric = numel(app.node_idx);
            app.node_count_theory = n - l - 1;

            app.r_mean_numeric = mean(app.accepted_r);
            app.r_mean_theory = (app.a/2) * (3*n^2 - l*(l+1));
            app.percent_error = 100 * abs(app.r_mean_numeric - app.r_mean_theory) / app.r_mean_theory;
        end

        function plotDensityAndDistribution(app, n, l, m)
            cla(app.DensityAxes);
            plot(app.DensityAxes, app.r_scan, app.R_density, 'LineWidth', 2, ...
                'Color', [0.3 0.3 0.75], 'DisplayName', '|R_{nl}(r)|^2');
            hold(app.DensityAxes, 'on');
            if ~isempty(app.node_idx)
                plot(app.DensityAxes, app.r_scan(app.node_idx), app.R_density(app.node_idx), ...
                    'rx', 'MarkerSize', 8, 'LineWidth', 2, 'DisplayName', 'Nodes');
            end
            title(app.DensityAxes, 'Radial probability density');
            xlabel(app.DensityAxes, 'r'); ylabel(app.DensityAxes, '|R_{nl}(r)|^2');
            legend(app.DensityAxes, 'Location', 'best');
            grid(app.DensityAxes, 'on');
            hold(app.DensityAxes, 'off');

            P_r = app.R_density .* app.r_scan.^2;
            P_r = P_r / trapz(app.r_scan, P_r);
            cla(app.DistributionAxes);
            plot(app.DistributionAxes, app.r_scan, P_r, 'LineWidth', 2, ...
                'Color', [0.2 0.6 0.2], 'DisplayName', 'P(r)');
            hold(app.DistributionAxes, 'on');
            if ~isempty(app.node_idx)
                plot(app.DistributionAxes, app.r_scan(app.node_idx), P_r(app.node_idx), ...
                    'rx', 'MarkerSize', 8, 'LineWidth', 2, 'DisplayName', 'Nodes');
            end
            title(app.DistributionAxes, 'Radial probability distribution');
            xlabel(app.DistributionAxes, 'r'); ylabel(app.DistributionAxes, 'P(r)');
            legend(app.DistributionAxes, 'Location', 'best');
            grid(app.DistributionAxes, 'on');
            hold(app.DistributionAxes, 'off');
        end

        function plotConvergence(app)
            N_list = round(logspace(2, log10(app.Ntarget), 12));
            r_mean_vs_N = zeros(size(N_list));
            for k = 1:length(N_list)
                r_mean_vs_N(k) = mean(app.accepted_r(1:N_list(k)));
            end
            error_vs_N = abs(r_mean_vs_N - app.r_mean_theory);

            cla(app.ConvergenceAxes);
            loglog(app.ConvergenceAxes, N_list, error_vs_N, 'o-', 'LineWidth', 2, ...
                'MarkerSize', 5, 'Color', [0.2 0.4 0.7], 'DisplayName', 'Numerical error');
            hold(app.ConvergenceAxes, 'on');
            ref_line = error_vs_N(1) * sqrt(N_list(1) ./ N_list);
            loglog(app.ConvergenceAxes, N_list, ref_line, '--', 'Color', [0.6 0.6 0.6], ...
                'DisplayName', 'Theoretical 1/\surdN');
            hold(app.ConvergenceAxes, 'off');
            title(app.ConvergenceAxes, 'Monte Carlo convergence');
            xlabel(app.ConvergenceAxes, 'N'); ylabel(app.ConvergenceAxes, 'Error in <r>');
            legend(app.ConvergenceAxes, 'Location', 'best', 'Interpreter', 'tex');
            grid(app.ConvergenceAxes, 'on');
        end

        function plotSurfaceViewer(app, n, l)
            theta_rev = linspace(0, 2*pi, 60);
            [Rr, Th] = meshgrid(app.r_scan, theta_rev);
            Zdensity = interp1(app.r_scan, app.R_density, Rr(1,:), 'linear', 'extrap');
            Zdensity = repmat(Zdensity, length(theta_rev), 1);
            X_rev = Rr .* cos(Th);
            Y_rev = Rr .* sin(Th);
            z_scale = 0.4 * app.Rmax / max(Zdensity(:));
            Z_rev = Zdensity * z_scale;

            cla(app.SurfaceAxes);
            surf(app.SurfaceAxes, X_rev, Y_rev, Z_rev, Zdensity, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
            colormap(app.SurfaceAxes, turbo);
            if isempty(app.SurfaceColorbar) || ~isvalid(app.SurfaceColorbar)
                app.SurfaceColorbar = colorbar(app.SurfaceAxes);
            end
            app.SurfaceColorbar.Label.String = 'Probability density';
            shading(app.SurfaceAxes, 'interp');
            camlight(app.SurfaceAxes);
            lighting(app.SurfaceAxes, 'gouraud');
            axis(app.SurfaceAxes, 'vis3d');
            app.SurfaceAxes.XTick = []; app.SurfaceAxes.YTick = []; app.SurfaceAxes.ZTick = [];
            app.SurfaceAxes.Color = [0.97 0.97 0.97];
            view(app.SurfaceAxes, 30, 25);
            title(app.SurfaceAxes, sprintf('Orbital radial surface viewer: n=%d, l=%d', n, l));
        end
    end

    methods (Access = public)
        function app = HydrogenOrbitalApp
            createComponents(app);
        end
    end
end