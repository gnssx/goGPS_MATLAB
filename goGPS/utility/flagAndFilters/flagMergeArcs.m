% SYNTAX:
%    flag = flagMergeArcs(flag, max_gap)
%
% DESCRIPTION:
%    merge arcs
%
% INPUT:
%   flag          [n_obs x n_arrays]
%   min_arc       n_epochs with no flags to activate at the border of a flagged interval

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

function flag = flagMergeArcs(flag, max_gap)
    tmp_flag = [true(max_gap, size(flag, 2)); flag; true(max_gap, size(flag, 2))];
    if mod(max_gap, 2) == 0
        tmp_flag = flagShrink(flagExpand(tmp_flag, max_gap/2), max_gap/2);
    else
        tmp_flag = flagShrink(flagExpand(tmp_flag, (max_gap-1)/2), (max_gap-1)/2);
        tmp_flag(2:end-1) = tmp_flag(2:end-1) | (tmp_flag(1:end-2) & tmp_flag(3:end));
    end
    flag = tmp_flag(max_gap + (1 : size(flag, 1)) ,:);
end
