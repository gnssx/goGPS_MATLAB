% SYNTAX:
%    lim = limMerge(lim, max_gap)
%
% DESCRIPTION:
%    merge limits closer than max_gap
%
% INPUT:
%   lim           limits as arrived from getOutliers
%   max_gap       n_epochs between intervals to merge

%--- * --. --- --. .--. ... * ---------------------------------------------
%               ___ ___ ___
%     __ _ ___ / __| _ | __|
%    / _` / _ \ (_ |  _|__ \
%    \__, \___/\___|_| |___/
%    |___/                    v 1.0 beta 2
%
%--------------------------------------------------------------------------
%  Copyright (C) 2009-2018 Mirko Reguzzoni, Eugenio Realini
%  Written by:       Andrea Gatti
%  Contributors:     Andrea Gatti
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

function lim = limMerge(lim, max_gap)
    % compute a moving window median to filter the data in input
    for l = size(lim, 1) - 1 : -1 : 1
        if (lim(l + 1, 1) - lim(l, 2)) < max_gap
            lim(l, 2) = lim(l + 1, 2);
            lim(l + 1, :) = [];
        end
    end
end
