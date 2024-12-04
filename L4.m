% Parameter für das L2-Modell
rho = 1000; % Dichte der Flüssigkeit in kg/m^3
A = 1; % Grundfläche in m^2
a = 0.003; % Querschnitt des Auslaufs in m^2
g = 9.81; % Erdbeschleunigung in m/s^2
qzu = 6.0; % Stationärer Zufluss in kg/s

c2 = 1 / (rho * A);
c3 = (a * a * rho * g) / (A * qzu);
num = [c3];
den = [1 c3];

% Übertragungsfunktion für das L2-Modell
G1 = tf(num, den);

% Serienkaskade von zwei L2-Modellen
G2 = G1; % Da beide Modelle gleich sind, setzen wir G2 = G1
G_total = series(G1, G2); % Serienverknüpfung der beiden Modelle

% Simulation der Sprungantwort
t = 0:1:600; % Zeitvektor von 0 bis 600 Sekunden in Schritten von 1 s
[y, t] = step(G_total, t);

% Berechnung des Verstärkungsfaktors (Endwert der Sprungantwort)
steady_state_value = y(end);

% Berechnung der Steigung der Sprungantwort bei t = 0
initial_slope = (y(2) - y(1)) / (t(2) - t(1));

% Berechnung der Zeitkonstanten (63,2% des Endwerts)
target_value = 0.632 * steady_state_value;
T_index = find(y >= target_value, 1); % Index für ersten Punkt bei 63.2% des Endwerts
T_approx = t(T_index); % Zeitkonstante T


% Ableitung (Wendetangente)
dy_dt = diff(y) ./ diff(t); % Numerische Ableitung der Sprungantwort
[~, wende_index] = max(dy_dt); % Index des maximalen Anstiegs (Wendepunkt)
t_w = t(wende_index); % Zeit des Wendepunkts
x_w = y(wende_index); % Sprungantwort beim Wendepunkt
slope_w = dy_dt(wende_index); % Steigung der Wendetangente

% Verzugszeit (T_e) basierend auf Tangente (Schnittpunkt mit y=0)
Te = t_w - x_w / slope_w;

% Ausgleichszeit (T_b) (Schnittpunkt der Tangente mit Endwert)
Tb = (steady_state_value - x_w) / slope_w + t_w;
Tb=Tb-Te;

% Plot erstellen
figure;
plot(t, y, 'b-', 'LineWidth', 1.5); % Plot in Blau mit Linienbreite 1.5
hold on;
yline(steady_state_value, 'g--'); % Verstärkungsfaktor-Linie
xline(Te, 'm--'); % Verzugszeit-Linie
xline(Tb, 'c--'); % klassische Ausgleichszeit-Linie
plot(t_w, x_w, 'ro', 'DisplayName', 'Wendepunkt'); % Wendepunkt
plot([t_w Tb], [x_w steady_state_value], 'r--', 'DisplayName', 'Wendetangente'); % Wendetangente
%xline(Tb, 'm--', ['T_b = ', num2str(t_b, '%.2f'), ' s']); % Ausgleichszeit-Linie

% Beschriftung der Verstärkungsfaktors und der Zeitkonstanten
text(20, steady_state_value - 0.05, ['K = ', num2str(steady_state_value, '%.2f'), ' m'], 'Color', 'green', 'HorizontalAlignment', 'left');
text(Te + 10, 0.1 * steady_state_value, ['T_e = ', num2str(Te, '%.2f'), ' s'], 'Color', 'magenta', 'HorizontalAlignment', 'left');
text(Tb + 10, 0.9 * steady_state_value, ['T_b = ', num2str(Tb, '%.2f'), ' s'], 'Color', 'cyan', 'HorizontalAlignment', 'left');

% Achsenbeschriftung und Titel
grid on;
xlabel('Zeit t (s)');
ylabel('Füllstand x(t) (m)');
title('Simulation der Sprungantwort für eine Kaskade von zwei L2-Modellen');
legend('Füllstand x(t)', 'Endwert (Gain)', 'Verzugszeit (T_e)', 'Ausgleichszeit (T_b)');

% Ergebnisse anzeigen
disp(['Verzugszeit Te: ', num2str(Te, '%.2f'), ' s']);
disp(['Ausgleichszeit Tb: ', num2str(Tb, '%.2f'), ' s']);

% Plot speichern
saveas(gcf, 'simulation_ergebnis_L4.png');
