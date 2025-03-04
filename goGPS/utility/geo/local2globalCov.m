function [Cyy] = local2globalCov(Cxx, X)

% SYNTAX:
%   [Cyy] = local2globalCov(Cxx, X);
%
% INPUT:
%   Cxx = input covariance matrices
%   X   = position vectors
%
% OUTPUT:
%   Cyy = output covariance matrices
%
% DESCRIPTION:
%   Covariance propagation from local-level reference frame to Earth-fixed reference frame

%--- * --. --- --. .--. ... * ---------------------------------------------
%               ___ ___ ___
%     __ _ ___ / __| _ | __|
%    / _` / _ \ (_ |  _|__ \
%    \__, \___/\___|_| |___/
%    |___/                    v 1.0 beta 2
%
%--------------------------------------------------------------------------
%  Copyright (C) 2009-2018 Mirko Reguzzoni, Eugenio Realini
%  Written by:
%  Contributors:     ...
%  A list of all the historical goGPS contributors is in CREDITS.nfo
%--------------------------------------------------------------------------
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%--------------------------------------------------------------------------
% 01100111 01101111 01000111 01010000 01010011
%--------------------------------------------------------------------------

%initialize new covariance matrices
Cyy = zeros(size(Cxx));

for i = 1 : size(X,2)

    %geodetic coordinates
    [phi, lam, h] = cart2geod(X(1,i), X(2,i), X(3,i)); %#ok<NASGU>

    %rotation matrix from global to local reference system
    R = [-sin(lam) cos(lam) 0;
         -sin(phi)*cos(lam) -sin(phi)*sin(lam) cos(phi);
         +cos(phi)*cos(lam) +cos(phi)*sin(lam) sin(phi)];

    %covariance propagation
    Cyy(:,:,i) = R' * Cxx(:,:,i) * R;
end

%----------------------------------------------------------------------------------------------
