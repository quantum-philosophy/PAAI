clear all;
clc;

Nrv = 4;
Nmcs = 1e5;

%% Generate a Pearson's correlation matrix.
%
S = randn(Nrv);
S = S' * S;
Cp = corrcov(S);

%% Convert it to the corresponding Spearman's one.
%
Cs = asin(Cp / 2) * 6 / pi;

%% Correlate the RVs.
%
R = chol(Cp);
Y = randn(Nmcs, Nrv) * R;
CsY = corr(Y, 'type', 'Spearman');

%% Transform the correlated normal RVs into uniform ones.
%
U = normcdf(Y);
CsU = corr(U, 'type', 'Spearman');

%% Transform the uniform RVs to, say, exponential RVs.
%
X = expinv(U);
CsX = corr(X, 'type', 'Spearman');

fprintf('Infinity norm for Y: %e\n', norm(Cs - CsY, Inf));
fprintf('Infinity norm for U: %e\n', norm(Cs - CsU, Inf));
fprintf('Infinity norm for X: %e\n', norm(Cs - CsX, Inf));
