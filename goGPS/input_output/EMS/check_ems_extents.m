function [ems_data_available] = check_ems_extents(time_R, pr, snr, nSatTot, Eph, SP3, iono, sbas, lambda, phase, p_rate)

% SYNTAX:
%   [ems_data_available] = check_ems_extents(time_R, pr, snr, nSatTot, Eph, SP3, iono, sbas, lambda, phase, p_rate);
%
% INPUT:
%   time_R = reference vector of GPS time of week
%   pr     = pseudorange
%   snr    = signal-to-noise ratio
%   nSatTot = total number of satellites (depending on the enabled constellations)
%   Eph    = broadcast ephemeris
%   SP3    = structure containing precise ephemeris data
%   iono   = ionospheric parameters (Klobuchar)
%   sbas   = SBAS corrections
%   lambda = wavelength matrix (depending on the enabled constellations)
%   phase  = L1 carrier (phase=1), L2 carrier (phase=2)
%   p_rate = processing interval [s]
%
% OUTPUT:
%   ems_data_available = boolean flag for data availability check
%
% DESCRIPTION:
%   Function that check that the approximate position of the receiver
%   (first available positioning epoch) is within the EMS grids.

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

ems_data_available = 0;

fprintf('Checking that the receiver approximate position falls within the available EMS grids... ');

pos_R = zeros(3,1);

if (~isempty(find(Eph(30,:,:) ~= 0, 1)) || ~isempty(SP3))

    cutoff = 15;
    snr_threshold = 0;

    i = 1;

    while (sum(abs((pos_R))) == 0 & i <= length(time_R))

        satObs = find(pr(:,i) ~= 0);

        Eph_t  = rt_find_eph (Eph, time_R(i), nSatTot);

        if (~isempty(SP3))
            satEph = SP3.prn;
        else
            satEph = find(Eph_t(1,:) ~= 0);
        end

        satAvail = intersect(satObs,satEph)';

        if (length(satAvail) >=4)
            pos_R = init_positioning(time_R(i), pr(satAvail,i), snr(satAvail,i), Eph_t(:,:), SP3, iono, [], [], [], [], satAvail, [], lambda(satAvail,:), cutoff, snr_threshold, phase, p_rate, 0, 0, 0);
        end

        i = i + 1;

    end
end

if (sum(abs((pos_R))) ~= 0)

    [lat_R, lon_R] = cart2geod(pos_R(1), pos_R(2), pos_R(3));

    igp4 = sel_igp(lat_R, lon_R, sbas.igp, sbas.lat_igp, sbas.lon_igp);

    if(isempty(igp4))
        fprintf('FALSE\n');
    else
        fprintf('TRUE\n');
        fprintf('EMS files successfully read. Applying SBAS corrections.\n');
        ems_data_available = 1;
    end
else
    fprintf('\n');
    fprintf('Positioning not possible. Processing stopped.\n');
    return
end
