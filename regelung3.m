% Parameter der Strecke
rho = 1000; % Dichte der Flüssigkeit in kg/Kubikmeter
A = 1; % Grundfläche in Quadratmeter
a = 0.003; % Querschnitt des Auslaufs in Quadratmeter
g = 9.81; % Erdbeschleunigung in m/Quadratsekunde
qzu = 6.0; % Stationärer Zufluss (im Arbeitspunkt) in kg/sec

% Streckenparameter
c2 = 1 / (rho * A);
c3 = (a * a * rho * g) / (A * qzu);

% Übertragungsfunktionen der Regelstrecke
G1 = tf([c2], [1, c3]);
G2 = tf([c3], [1, c3]);
G_total = series(G1, G2); % Serienverknüpfung

% Streckenparameter
Ks = 0.068; % Verstärkung
Te = 19.14; % Verzugszeit
Tb = 184.47; % Ausgleichszeit

% PI-Regler H1(s) (20% Überschwingen)
KPR1 = 0.6 * Tb / (Te * Ks); % Proportionalverstärkung
Ti1 = Tb;                   % Integrationszeit
H1 = KPR1 * tf([Ti1, 1], [Ti1, 0]);

% Führungsübertragungsfunktion GCL1(s)
GCL1 = feedback(G_total * H1, 1);

% PI-Regler H2(s) (kein Überschwingen)
KPR2 = 0.35 * Tb / (Te * Ks); % Reduzierte Proportionalverstärkung
Ti2 = 1.2 * Tb;              % Längere Integrationszeit
H2 = KPR2 * tf([Ti2, 1], [Ti2, 0]);

% Führungsübertragungsfunktion GCL2(s)
GCL2 = feedback(G_total * H2, 1);

% Simulation der Sprungantworten
t = 0:0.1:600; % Zeitvektor
delta_w = 0.01; % Führungssprunghöhe

[y0, t0] = step(delta_w * G_total, t); % Antwort für Strecke
[y1, t1] = step(delta_w * GCL1, t); % Antwort für H1
[y2, t2] = step(delta_w * GCL2, t); % Antwort für H2

% Analyse der Ergebnisse
% Toleranzgrenzen (±5 %)
upper_bound = delta_w * 1.05;
lower_bound = delta_w * 0.95;

% Anregelzeit Tcr
Tcr1 = find(y1 >= 0.95 * delta_w, 1) * (t(2) - t(1)); % Für H1
Tcr2 = find(y2 >= 0.95 * delta_w, 1) * (t(2) - t(1)); % Für H2

% Ausregelzeit Tcs
Tcs1 = find(abs(y1 - delta_w) <= 0.05 * delta_w, 1, 'last') * (t(2) - t(1)); % Für H1
Tcs2 = find(abs(y2 - delta_w) <= 0.05 * delta_w, 1, 'last') * (t(2) - t(1)); % Für H2

% Maximale Regelabweichung xw,max
xw_max1 = max(abs(delta_w - y1)); % Für H1
xw_max2 = max(abs(delta_w - y2)); % Für H2

% Bleibende Regelabweichung xw,stat
xw_stat1 = abs(delta_w - y1(end)); % Für H1
xw_stat2 = abs(delta_w - y2(end)); % Für H2

% Stabilität des Regelkreises
eig1 = eig(GCL1);
eig2 = eig(GCL2);

% Plot der Sprungantwort der Strecke
figure;
plot(t0, y0, 'g-', 'LineWidth', 1.5);
xlabel('Zeit t (s)');
ylabel('Regelgröße x(t)');
title('Sprungantwort der Strecke G_{total}');
grid on;
saveas(gcf, 'R3_Strecke.png'); 

% Plot der Sprungantwort H1 (20% Überschwingen)
figure;
plot(t1, y1, 'r-', 'LineWidth', 1.5); hold on;
plot(t, upper_bound * ones(size(t)), 'k--', 'LineWidth', 1);
plot(t, lower_bound * ones(size(t)), 'k--', 'LineWidth', 1);
xlabel('Zeit t (s)');
ylabel('Regelgröße x(t)');
title('Sprungantwort mit PI-Regler H1 (20% Überschwingen)');
grid on;
saveas(gcf, 'R3_H1.png');

% Plot der Sprungantwort H2 (kein Überschwingen)
figure;
plot(t2, y2, 'b-', 'LineWidth', 1.5); hold on;
plot(t, upper_bound * ones(size(t)), 'k--', 'LineWidth', 1);
plot(t, lower_bound * ones(size(t)), 'k--', 'LineWidth', 1);
xlabel('Zeit t (s)');
ylabel('Regelgröße x(t)');
title('Sprungantwort mit PI-Regler H2 (kein Überschwingen)');
grid on;
saveas(gcf, 'R3_H2.png');

% Gesamtdiagramm: Alle Sprungantworten zusammen
figure;
hold on;
%plot(t0, y0, 'g-', 'LineWidth', 1.5); % Sprungantwort der Strecke
plot(t1, y1, 'r-', 'LineWidth', 1.5); % Sprungantwort H1
plot(t2, y2, 'b-', 'LineWidth', 1.5); % Sprungantwort H2
plot(t, upper_bound * ones(size(t)), 'k--', 'LineWidth', 1);
plot(t, lower_bound * ones(size(t)), 'k--', 'LineWidth', 1);
xlabel('Zeit t (s)');
ylabel('Regelgröße x(t)');
title('Gesamtdiagramm: Sprungantworten der Strecke und PI-Regler');
legend( 'H1: 20% Überschwingen', 'H2: Kein Überschwingen', ...
    '+5% Toleranzgrenze', '-5% Toleranzgrenze', ...
    'Location', 'southeast');
grid on;
saveas(gcf, 'R3_Gesamt.png');

% Ergebnisse ausgeben
disp(['Anregelzeit Tcr (H1): ', num2str(Tcr1), ' s']);
disp(['Anregelzeit Tcr (H2): ', num2str(Tcr2), ' s']);
disp(['Ausregelzeit Tcs (H1): ', num2str(Tcs1), ' s']);
disp(['Ausregelzeit Tcs (H2): ', num2str(Tcs2), ' s']);
disp(['Maximale Regelabweichung xw_max (H1): ', num2str(xw_max1)]);
disp(['Maximale Regelabweichung xw_max (H2): ', num2str(xw_max2)]);
disp(['Bleibende Regelabweichung xw_stat (H1): ', num2str(xw_stat1)]);
disp(['Bleibende Regelabweichung xw_stat (H2): ', num2str(xw_stat2)]);
disp('Eigenwerte von GCL1 (H1):');
disp(eig1);
disp('Eigenwerte von GCL2 (H2):');
disp(eig2);
