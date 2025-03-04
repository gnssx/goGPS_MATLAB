function GSVlines = NMEA_GSV_gen(sat, el, az, snr, constellations)

% SYNTAX:
%   GSVlines = NMEA_GSV_gen(sat, el, az, snr, constellations);
%
% INPUT:
%   sat = list of visible satellites
%   el = elevation [deg]
%   az = azimuth [deg]
%   snr = signal-to-noise ratio [dB]
%   constellations = struct with multi-constellation settings
%                   (see goGNSS.initConstellation - empty if not available)
%
% OUTPUT:
%   GSVlines = $GPGSV sentence(s) (NMEA)
%
% DESCRIPTION:
%   Returns (a) $GPGSV sentence(s) in NMEA 0183 format.

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

if (isempty(constellations)) %then use only GPS as default
    constellations.GPS = struct('numSat', 32, 'enabled', 1, 'indexes', [1:32], 'PRN', [1:32]);
    constellations.nEnabledSat = 32;
    constellations.indexes = constellations.GPS.indexes;
    constellations.PRN     = constellations.GPS.PRN;
end

%number of satellites
nsat = size(sat,1);

%-----------------------------------------------------------------------------------------------
% COMPOSITION OF THE NMEA SENTENCE
%-----------------------------------------------------------------------------------------------

%number of GSV sentences (max 4 satellites per sentence)
n = ceil(nsat/4);

%variable to store the n GSV sentences
GSVlines = [];

%satellite PRN
sat_prn = constellations.PRN(sat);

for i = 1 : n
    nmeastring = sprintf('$GPGSV,%d,%d,%d', n, i, nsat);
    for j = 1 : 4
        index = 4*(i-1) + j;
        if (index <= nsat)
            nmeastring = [nmeastring sprintf(',%d,%d,%d,%d', sat_prn(index), round(el(index)), round(az(index)), round(snr(index)))];
        else
            nmeastring = [nmeastring ',,,,'];
        end
    end

    %checksum computation
    checksum = NMEA_checksum(nmeastring);
    nmeastring = [nmeastring '*' checksum];

    %add the new string to the GSV group
    GSVlines = [GSVlines nmeastring];

    %add new line character between GSV sentences
    %(but not at the end of the overall string)
    if (i ~= n)
        GSVlines = [GSVlines '\n'];
    end
end
