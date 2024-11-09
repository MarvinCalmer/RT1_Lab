rho = 1000; % Dichte der Flüssigkeit in kg/Kubikmeter
A = 1; % Grundfläche in Quadratmeter
a = 0.003; % Querschnitt des Auslaufs in Quadratmeter
g = 9.81; % Erdbeschleunigung in m/Quadratsekunde
qzu = 6.0; % Stationärer Zufluss (im Arbeitspunkt) in kg/sec

c2=1/(rho*A);
c3=(a*a*rho*g)/(A*qzu);
s = tf('s');
G1=c2/s;

% Simulation der Sprungantwort
t = 0:0.5:500; % Zeitvektor von 0 bis 500 Sekunden in Schritten von 0.5 s
[y, t] = step(G1, t);

% Bestimmung eines Punktes für das Steigungsdreieck
t1 = 100; % Zeit für den Anfang des Dreiecks
t2 = 200; % Zeit für das Ende des Dreiecks
y1 = c2 * t1; % Wert der Sprungantwort bei t1
y2 = c2 * t2; % Wert der Sprungantwort bei t2

% Plot erstellen
figure;
plot(t, y, 'b-', 'LineWidth', 1.5); % Plot in Blau mit Linienbreite 1.5
hold on;

% Zeichne das Steigungsdreieck
plot([t1, t2], [y1, y1], 'k--'); % Horizontale Linie des Dreiecks
plot([t2, t2], [y1, y2], 'k--'); % Vertikale Linie des Dreiecks

% Annotationswerte für das Steigungsdreieck
text((t1 + t2) / 2, y1 - 2, ['\Delta t = ' num2str(t2 - t1) ' s'], 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
text(t2 + 5, (y1 + y2) / 2, ['\Delta x = ' num2str(y2 - y1, '%.2f') ' m'], 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');

% Steigung c2 annotieren
text(t2 + 10, y2, ['Steigung c2 = ' num2str(c2, '%.4f') ' m/(kg*s)'], 'Color', 'red', 'HorizontalAlignment', 'left');

% Achsenbeschriftung und Titel
grid on;
xlabel('Zeit t (s)');
ylabel('Füllstand x(t) (m)');
title('Simulation des Füllstands für ein integratives Behältermodell mit Steigungsdreieck');
legend('Füllstand x(t)');


% Plot speichern
saveas(gcf, 'simulation_ergebnis_L3.png'); % Speichern des Plots als PNG-Datei