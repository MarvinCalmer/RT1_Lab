rho = 1000; % Dichte der Flüssigkeit in kg/Kubikmeter
A = 1; % Grundfläche in Quadratmeter
a = 0.003; % Querschnitt des Auslaufs in Quadratmeter
g = 9.81; % Erdbeschleunigung in m/Quadratsekunde
qzu = 6.0; % Stationärer Zufluss (im Arbeitspunkt) in kg/sec

% Streckenparameter
TS = 68;
KS = 0.068;

c2 = 1 / (rho * A);
c3 = (a * a * rho * g) / (A * qzu);
num = [c2];
den = [1 c3]; 
G1 = tf(num, den);

% Berechnung der Reglerparameter
KPR_PI = 0.5; % PI-Regler
Ti = TS; 

% PI-Regler
H2 = tf([KPR_PI * Ti, KPR_PI], [1, 0]); % Zähler: KPR_PI * (Ti*s + 1), Nenner: Ti*s

% Führungsübertragungsfunktionen
GCL2 = feedback(G1 * H2, 1); % Mit PI-Regler

% Störübertragungsfunktion (F(s) = G(s) / (1 + G(s)*H(s)))
F = G1 / (1 + G1 * H2); % Störübertragungsfunktion

% Führungs-Sprungantwort des Regelkreises (Änderung des Sollwertes um 1 cm)
delta_w = 0.01; % Sprunghöhe

% Simulieren der Antwort für die Störung
t = 0:0.1:600; % Zeitvektor für die Simulation
[y_s, t_s] = step(G1, t); % Sprungantwort der Strecke
[y_cl, t_cl] = step(delta_w * GCL2, t); % Sprungantwort des geschlossenen Regelkreises
[y2, t2] = step(GCL2, t); % Sprungantwort PI-Regler

% Störungseintrag (∆z = 1.0)
z_value = 1.0; % Störungshöhe
[y_z, t_z] = step(z_value * F, t); % Störsprungantwort des geschlossenen Regelkreises

% Sollwert und Korridor
upper_limit = delta_w * 1.05; % +5%
lower_limit = delta_w * 0.95; % -5%

% Berechnung von T_cr und T_cs für PI-Regler
Tcr2 = t2(find(y_cl >= lower_limit, 1)); % Erste Zeit im Korridor
Tcs2_idx = find(y_cl < lower_limit | y2 > upper_limit, 1, 'last'); % Letzter Punkt außerhalb des Korridors
if isempty(Tcs2_idx)
    Tcs2 = Tcr2; % Falls sofort im Korridor bleibt
else
    Tcs2 = t2(Tcs2_idx) + 0.1; % Ausregelzeit
end

% Berechnung der maximalen Regelabweichung und bleibende Regelabweichung
xw_max_PI = max(abs(delta_w - y2)); % Maximale Regelabweichung für PI-Regler
xw_stat_PI = abs(delta_w - y2(end)); % Bleibende Regelabweichung für PI-Regler

% Berechnung der maximalen Regelabweichung für den dritten Plot (Störsprungantwort)
xw_max_stoerung = max(abs(z_value - y_z)); % Maximale Regelabweichung durch Störung

% Berechnung der Zeit, bis die Regelabweichung maximal 2 mm beträgt
time_to_2mm = t2(find(abs(delta_w - y2) <= 0.002, 1)); % Zeit, bis die Regelabweichung 2 mm erreicht

% Stabilitätsprüfung (Stabilität prüfen, ob alle Pole im linken Halbebenenbereich liegen)
is_stable_PI = all(real(pole(GCL2)) < 0); % Stabile Pole?

% Ergebnisse ausgeben
fprintf('Führungs-Sprungantwort (Mittlerer Plot):\n');
fprintf('Maximale Regelabweichung xw_max = %.4f\n', xw_max_PI);
fprintf('Bleibende Regelabweichung xw_stat = %.4f\n', xw_stat_PI);
fprintf('Anregelzeit Tcr = %.4f s\n', Tcr2);
fprintf('Ausregelzeit Tcs = %.4f s\n', Tcs2);
fprintf('Stabil: %s\n', string(is_stable_PI));

fprintf('Stör-Sprungantwort (Dritter Plot):\n');
fprintf('Maximale Regelabweichung xw_max durch Störung = %.4f\n', xw_max_stoerung);

fprintf('Dauer, bis die Regelabweichung maximal 2 mm beträgt: %.4f s\n', time_to_2mm);

% Plots erstellen und separat speichern

% Erster Plot: Sprungantwort der Strecke ohne Regelung
figure;
plot(t_s, y_s, 'g', 'LineWidth', 1.5); 
xlabel('Zeit [s]');
ylabel('Regelgröße x');
title('Sprungantwort der Strecke ohne Regelung');
grid on;
saveas(gcf, 'Sprungantwort_Strecke_ohne_Regelung.png'); % Speichern des ersten Plots als PNG-Datei

% Zweiter Plot: Sprungantwort des geschlossenen Regelkreises
figure;
plot(t_cl, y_cl, 'b', 'LineWidth', 1.5); 
hold on;
yline(delta_w, 'k--', 'LineWidth', 1.2); % Sollwert
yline(upper_limit, 'r--', 'LineWidth', 1.2); % +5%
yline(lower_limit, 'r--', 'LineWidth', 1.2); % -5%
plot([Tcr2, Tcr2], [0, delta_w], 'g--', 'LineWidth', 1.5); % Anregelzeit
plot([Tcs2, Tcs2], [0, delta_w], 'm--', 'LineWidth', 1.5); % Ausregelzeit
xlabel('Zeit [s]');
ylabel('Regelgröße x');
title('Sprungantwort des geschlossenen Regelkreises');
grid on;
legend('Sprungantwort', 'Sollwert w=0.001', '+5%', '-5%', 'Anregelzeit Tcr', 'Ausregelzeit Tcs', 'Location','southeast');
saveas(gcf, 'Sprungantwort_Regelkreis.png'); % Speichern des zweiten Plots als PNG-Datei

% Dritter Plot: Störsprungantwort des geschlossenen Regelkreises
figure;
plot(t_z, y_z, 'r', 'LineWidth', 1.5);
yline(0.002, 'r--', 'LineWidth', 1.2); % Sollwertlinie für Störung
xlabel('Zeit [s]');
ylabel('Regelgröße x');
title('Störsprungantwort des geschlossenen Regelkreises');
grid on;
saveas(gcf, 'Stoersprungantwort_Regelkreis.png'); % Speichern des dritten Plots als PNG-Datei

% Gesamte Grafik mit Subplots speichern
figure;
subplot(3,1,1); % 3x1 Subplot, erster Plot
plot(t_s, y_s, 'g', 'LineWidth', 1.5); 
xlabel('Zeit [s]');
ylabel('Regelgröße x');
title('Sprungantwort der Strecke ohne Regelung');
grid on;

subplot(3,1,2); % 3x1 Subplot, zweiter Plot
plot(t_cl, y_cl, 'b', 'LineWidth', 1.5); 
hold on;
yline(delta_w, 'k--', 'LineWidth', 1.2); % Sollwert
yline(upper_limit, 'r--', 'LineWidth', 1.2); % +5%
yline(lower_limit, 'r--', 'LineWidth', 1.2); % -5%
plot([Tcr2, Tcr2], [0, delta_w], 'g--', 'LineWidth', 1.5); % Anregelzeit
plot([Tcs2, Tcs2], [0, delta_w], 'm--', 'LineWidth', 1.5); % Ausregelzeit
xlabel('Zeit [s]');
ylabel('Regelgröße x');
title('Sprungantwort des geschlossenen Regelkreises');
grid on;
legend('Sprungantwort', 'Sollwert w=0.001', '+5%', '-5%', 'Anregelzeit Tcr', 'Ausregelzeit Tcs', 'Location','southeast');

subplot(3,1,3); % 3x1 Subplot, dritter Plot
plot(t_z, y_z, 'r', 'LineWidth', 1.5);
yline(0.002, 'r--', 'LineWidth', 1.2); % Sollwertlinie für Störung
xlabel('Zeit [s]');
ylabel('Regelgröße x');
title('Störsprungantwort des geschlossenen Regelkreises');
grid on;

% Speichern der gesamten Grafik mit Subplots
saveas(gcf, 'simulation_ergebnis_mit_subplots.png'); % Speichern der gesamten Subplot-Grafik als PNG-Datei
