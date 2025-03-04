function [serialObj] = configure_fastrax(serialObj, COMportR, prot_par, rate)

% SYNTAX:
%   [serialObj] = configure_fastrax(serialObj, COMportR, prot_par, rate);
%
% INPUT:
%   serialObj = handle to the rover serial object
%   COMportR = serial port the receiver is connected to
%   prot_par = receiver-specific parameters
%   rate = measurement rate to be set (default = 1 Hz)
%
% OUTPUT:
%   serialObj = handle to the rover serial object (it may have been re-created)
%
% DESCRIPTION:
%   Configure Fastrax receivers to be used with goGPS.

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

% iTalk transaction ID
tran_id = 10;

italk_reset_default(serialObj, tran_id);

% set output rate (and raw measurement output)
if (nargin < 4)
    rate = 1;
end
fprintf('Setting measurement rate to %dHz... ', rate);

reply_RATE = italk_TRACK_MEAS_INTERVAL(serialObj, tran_id, rate*1000);
tries = 0;

while (~reply_RATE)
    tries = tries + 1;
    if (tries > 3)
        break
    end
    % close and delete old serial object
    try
        fclose(serialObj);
        delete(serialObj);
    catch
        stopasync(serialObj);
        fclose(serialObj);
        delete(serialObj);
    end
    % create new serial object
    serialObj = serial (COMportR,'BaudRate',prot_par{2,1});
    set(serialObj,'InputBufferSize',prot_par{3,1});
    fopen(serialObj);
    tran_id = tran_id + 1;
    reply_RATE = italk_TRACK_MEAS_INTERVAL(serialObj, tran_id, rate*1000);
end

if (reply_RATE)
    fprintf('done\n');
else
    fprintf(2, 'failed\n');
end

% enable GPS TOW synchronization
fprintf('Enabling GPS TOW synchronization... ');

tran_id = tran_id + 1;
reply_SYNC = italk_PPS_SYNC_TRACK(serialObj, tran_id, 1);
tries = 0;

while (~reply_SYNC)
    tries = tries + 1;
    if (tries > 3)
        break
    end
    % close and delete old serial object
    try
        fclose(serialObj);
        delete(serialObj);
    catch
        stopasync(serialObj);
        fclose(serialObj);
        delete(serialObj);
    end
    % create new serial object
    serialObj = serial (COMportR,'BaudRate',prot_par{2,1});
    set(serialObj,'InputBufferSize',prot_par{3,1});
    fopen(serialObj);
    tran_id = tran_id + 1;
    reply_SYNC = italk_PPS_SYNC_TRACK(serialObj, tran_id, 1);
end

if (reply_SYNC)
    fprintf('done\n');
else
    fprintf(2, 'failed\n');
end

% set offset from GPS TOW
fprintf('Setting offset from GPS TOW to zero... ');

tran_id = tran_id + 1;
reply_OFFSET = italk_PPS_MEAS_MS(serialObj, tran_id, 0);
tries = 0;

while (~reply_OFFSET)
    tries = tries + 1;
    if (tries > 3)
        break
    end
    % close and delete old serial object
    try
        fclose(serialObj);
        delete(serialObj);
    catch
        stopasync(serialObj);
        fclose(serialObj);
        delete(serialObj);
    end
    % create new serial object
    serialObj = serial (COMportR,'BaudRate',prot_par{2,1});
    set(serialObj,'InputBufferSize',prot_par{3,1});
    fopen(serialObj);
    tran_id = tran_id + 1;
    reply_OFFSET = italk_PPS_MEAS_MS(serialObj, tran_id, 0);
end

if (reply_OFFSET)
    fprintf('done\n');
else
    fprintf(2, 'failed\n');
end

% enable raw measurements output
fprintf('Enabling raw data output... ');

tran_id = tran_id + 1;
reply_RAW = italk_enable_raw(serialObj, tran_id);
tries = 0;

while (~reply_RAW)
    tries = tries + 1;
    if (tries > 3)
        break
    end
    % close and delete old serial object
    try
        fclose(serialObj);
        delete(serialObj);
    catch
        stopasync(serialObj);
        fclose(serialObj);
        delete(serialObj);
    end
    % create new serial object
    serialObj = serial (COMportR,'BaudRate',prot_par{2,1});
    set(serialObj,'InputBufferSize',prot_par{3,1});
    fopen(serialObj);
    tran_id = tran_id + 1;
    reply_RAW = italk_enable_raw(serialObj, tran_id);
end

if (reply_RAW)
    fprintf('done\n');
else
    fprintf(2, 'failed\n');
end
