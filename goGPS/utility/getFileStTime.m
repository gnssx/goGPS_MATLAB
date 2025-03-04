%--- * --. --- --. .--. ... * ---------------------------------------------
%               ___ ___ ___
%     __ _ ___ / __| _ | __|
%    / _` / _ \ (_ |  _|__ \
%    \__, \___/\___|_| |___/
%    |___/                    v 1.0 beta 2
%
%--------------------------------------------------------------------------
%  Copyright (C) 2009-2018 Mirko Reguzzoni, Eugenio Realini
%  Written by: Giulio Tagliaferro
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

function time = getFileStTime(filename)
% Return the start time of the file using the standard naming convention

% xGiulio: This function must be changed in such a way that the epoch is read from the file

    [~,name, ext] = fileparts(filename);
    if strcmpi(ext,'.eph') || strcmpi(ext,'.sp3') || strcmpi(ext,'.pre') || strcmpi(ext,'.clk') || strcmpi(ext,'.clk_30s') || strcmpi(ext,'.clk_05s')
        % name should be : cccwwwwd
        if length(name) == 8
            week = str2double(name(4:7));
            dow = str2double(name(8));
            if ~isnan(week) && ~isnan(dow)
                time = GPS_Time.fromWeekDow(week, dow);
            else
                time = [];
            end
        else
            time = [];
        end
    end
end
