rho = 1000; % Dichte der Flüssigkeit in kg/Kubikmeter
A = 1; % Grundfläche in Quadratmeter
a = 0.003; % Querschnitt des Auslaufs in Quadratmeter
g = 9.81; % Erdbeschleunigung in m/Quadratsekunde
qzu = 6.0; % Stationärer Zufluss (im Arbeitspunkt) in kg/sec
Tt = 27; % Totzeit in Sekunden

%Streckenparameter
TS=68;
KS=0.068;

c2=1/(rho*A);
c3=(a*a*rho*g)/(A*qzu);
num = [c2];
den = [1 c3]; 
G1 = tf(num, den);
s = tf('s');
% Übertragungsfunktion mit Totzeit
G2 = G1 * exp(-Tt * s);



% Berechnung der Reglerparameter
KPR_P = TS / (KS * Tt); % P-Regler
KPR_PI = 0.9 * TS / (KS * Tt); % PI-Regler
Ti = 3.3 * Tt; % Nach Ziegler und Nichols

% Ergebnisse ausgeben
fprintf('P-Regler:\nKPR_P = %.3f\n', KPR_P);
fprintf('PI-Regler:\nKPR_PI = %.3f\nTi = %.3f s\n', KPR_PI, Ti);

% P-Regler
H1 = tf(KPR_P); % Nur Verstärkung

% PI-Regler
H2 = tf([KPR_PI * Ti, KPR_PI], [Ti, 0]); % Zähler: KPR_PI * (Ti*s + 1), Nenner: Ti*s

% Führungsübertragungsfunktionen
GCL1 = feedback(G2 * H1, 1); % Mit P-Regler
GCL2 = feedback(G2 * H2, 1); % Mit PI-Regler

% Simuliere Sprungantworten
t = 0:0.1:500; % Zeitvektor für die Simulation
[y0, t1] = step(G2, t); % Sprungantwort P-Regler
[y1, t1] = step(GCL1, t); % Sprungantwort P-Regler
[y2, t2] = step(GCL2, t); % Sprungantwort PI-Regler

% Sollwert und Korridor
w = 1; % Sollwert
upper_limit = w * 1.05; % +5%
lower_limit = w * 0.95; % -5%

% Berechnung von T_cr und T_cs für P-Regler
Tcr1 = t1(find(y1 >= lower_limit, 1)); % Erste Zeit im Korridor
Tcs1_idx = find(y1 < lower_limit | y1 > upper_limit, 1, 'last'); % Letzter Punkt außerhalb des Korridors
if isempty(Tcs1_idx)
    Tcs1 = Tcr1; % Falls sofort im Korridor bleibt
else
    Tcs1 = t1(Tcs1_idx) + 0.1; % Ausregelzeit
end

% Berechnung von T_cr und T_cs für PI-Regler
Tcr2 = t2(find(y2 >= lower_limit, 1)); % Erste Zeit im Korridor
Tcs2_idx = find(y2 < lower_limit | y2 > upper_limit, 1, 'last'); % Letzter Punkt außerhalb des Korridors
if isempty(Tcs2_idx)
    Tcs2 = Tcr2; % Falls sofort im Korridor bleibt
else
    Tcs2 = t2(Tcs2_idx) + 0.1; % Ausregelzeit
end


% Maximale Regelabweichung
xw_max_P = max(abs(w - y1)); % Für P-Regler
xw_max_PI = max(abs(w - y2)); % Für PI-Regler

% Bleibende Regelabweichung (Differenz im stationären Zustand)
xw_stat_P = abs(w - y1(end)); % Für P-Regler
xw_stat_PI = abs(w - y2(end)); % Für PI-Regler

% Stabilitätsprüfung (hier aus den Antworten abzuleiten)
is_stable_P = all(real(pole(GCL1)) < 0); % Stabile Pole?
is_stable_PI = all(real(pole(GCL2)) < 0); % Stabile Pole?

% Ergebnisse ausgeben
fprintf('P-Regler:\n');
fprintf('Maximale Regelabweichung xw_max = %.4f\n', xw_max_P);
fprintf('Bleibende Regelabweichung xw_stat = %.4f\n', xw_stat_P);
fprintf('Anregelzeit= %.4f\n', Tcr1);
fprintf('Ausregelzeit = %.4f\n', Tcs1);
fprintf('Stabil: %s\n\n', string(is_stable_P));

fprintf('PI-Regler:\n');
fprintf('Maximale Regelabweichung xw_max = %.4f\n', xw_max_PI);
fprintf('Bleibende Regelabweichung xw_stat = %.4f\n', xw_stat_PI);
fprintf('Anregelzeit= %.4f\n', Tcr2);
fprintf('Ausregelzeit = %.4f\n', Tcs2);
fprintf('Stabil: %s\n', string(is_stable_PI));

% Plots erstellen
figure;

% P-Regler
subplot(2,1,1);
plot(t1, y1, 'b', 'LineWidth', 1.5); hold on;
yline(w, 'k--', 'LineWidth', 1.2); % Sollwert
yline(upper_limit, 'r--', 'LineWidth', 1.2); % +5%
yline(lower_limit, 'r--', 'LineWidth', 1.2); % -5%
plot([Tcr1, Tcr1], [0, w], 'g--', 'LineWidth', 1.5); % Anregelzeit
plot([Tcs1, Tcs1], [0, w], 'm--', 'LineWidth', 1.5); % Ausregelzeit
xlabel('Zeit [s]');
ylabel('Regelgröße x');
title('Führungssprungantwort mit P-Regler');
legend('Sprungantwort', 'Sollwert w=1', '+5%', '-5%', 'Anregelzeit Tcr1', 'Ausregelzeit Tcs1','Location','southeast');
grid on;

% PI-Regler
subplot(2,1,2);
plot(t2, y2, 'b', 'LineWidth', 1.5); hold on;
yline(w, 'k--', 'LineWidth', 1.2); % Sollwert
yline(upper_limit, 'r--', 'LineWidth', 1.2); % +5%
yline(lower_limit, 'r--', 'LineWidth', 1.2); % -5%
plot([Tcr2, Tcr2], [0, w], 'g--', 'LineWidth', 1.5); % Anregelzeit
plot([Tcs2, Tcs2], [0, w], 'm--', 'LineWidth', 1.5); % Ausregelzeit
xlabel('Zeit [s]');
ylabel('Regelgröße x');
title('Führungssprungantwort mit PI-Regler');
legend('Sprungantwort', 'Sollwert w=1', '+5%', '-5%', 'Anregelzeit Tcr2', 'Ausregelzeit Tcs2','Location','southeast');
grid on;
saveas(gcf, 'simulation_ergebnis_R1.png'); % Speichern des Plots als PNG-Datei
% 
% Plot erstellen
figure;
plot(t1, y0, 'b-', 'LineWidth', 1.5); % Plot in Blau mit Linienbreite 1.5
hold on;
yline(0.068, 'g--'); % Verstärkungsfaktor-Linie
%xline(T_approx, 'r--'); % Zeitkonstanten-Linie
%plot(T_approx, target_value, 'ro'); % Markierung des Punktes bei Zeitkonstante

% Horizontale Beschriftung des Verstärkungsfaktors und der Zeitkonstante
%text(T_approx + 20, target_value, ['T = ', num2str(T_approx, '%.2f'), ' s'], 'Color', 'red', 'HorizontalAlignment', 'left');
%text(20, 0.068 - 0.05, ['K = ', num2str(0.068, '%.2f'), ' m'], 'Color', 'green', 'HorizontalAlignment', 'left');

% Achsenbeschriftung und Titel
grid on;
xlabel('Zeit t (s)');
ylabel('Füllstand x(t) (m)');
title('Simulation des Füllstands mit Totzeit ');
legend('Füllstand x(t)', 'Endwert (Gain)', 'Zeitkonstante (T)');


% Plot speichern
saveas(gcf, 'Strecke_R1.png'); % Speichern des Plots als PNG-Datei