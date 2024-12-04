rho = 1000; % Dichte der Flüssigkeit in kg/Kubikmeter
A = 1; % Grundfläche in Quadratmeter
a = 0.003; % Querschnitt des Auslaufs in Quadratmeter
g = 9.81; % Erdbeschleunigung in m/Quadratsekunde
qzu = 6.0; % Stationärer Zufluss (im Arbeitspunkt) in kg/sec

c2=1/(rho*A);
c3=(a*a*rho*g)/(A*qzu);
num = [c3];
den = [1 c3]; 
G1 = tf(num, den);

% Simulation der Sprungantwort
t = 0:0.5:500; % Zeitvektor von 0 bis 500 Sekunden in Schritten von 0.5 s
[y, t] = step(G1, t);

% Berechnung des Verstärkungsfaktors (Endwert der Sprungantwort)
steady_state_value = y(end);

% Berechnung der Zeitkonstanten (63,2% des Endwerts)
target_value = 0.632 * steady_state_value;
T_index = find(y >= target_value, 1); % Index für ersten Punkt bei 63.2% des Endwerts
T_approx = t(T_index); % Zeitkonstante T

% Plot erstellen
figure;
plot(t, y, 'b-', 'LineWidth', 1.5); % Plot in Blau mit Linienbreite 1.5
hold on;
yline(steady_state_value, 'g--'); % Verstärkungsfaktor-Linie
xline(T_approx, 'r--'); % Zeitkonstanten-Linie
plot(T_approx, target_value, 'ro'); % Markierung des Punktes bei Zeitkonstante

% Horizontale Beschriftung des Verstärkungsfaktors und der Zeitkonstante
text(T_approx + 20, target_value, ['T = ', num2str(T_approx, '%.2f'), ' s'], 'Color', 'red', 'HorizontalAlignment', 'left');
text(20, steady_state_value - 0.05, ['K = ', num2str(steady_state_value, '%.2f'), ' m'], 'Color', 'green', 'HorizontalAlignment', 'left');

% Achsenbeschriftung und Titel
grid on;
xlabel('Zeit t (s)');
ylabel('Abfluss y(t) (m)');
title('Simulation des Abflusses für ein lineares Behältermodell L2');
legend('Abfluss q(t)', 'Endwert (Gain)', 'Zeitkonstante (T)');
% Plot speichern
saveas(gcf, 'simulation_ergebnis_L2.png'); % Speichern des Plots als PNG-Datei