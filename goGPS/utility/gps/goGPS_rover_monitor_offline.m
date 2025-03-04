function goGPS_rover_monitor_offline(fileIN, filerootOUT, protocol, flag_var_dyn_model, flag_stopGOstop, flag_simul)

% SYNTAX:
%   goGPS_rover_monitor_offline(fileIN, filerootOUT, protocol, flag_var_dyn_model, flag_stopGOstop, flag_simul);
%
% INPUT:
%   fileIN = input file (binary stream)
%   filerootOUT = output file prefix
%   protocol    = protocol verctor (0:Ublox, 1:Fastrax, 2:SkyTraq, 3:NVS)
%   flag_var_dyn_model = enable / disable variable dynamic model
%   flag_stopGOstop    = enable / disable stop-go-stop procedure for direction estimation
%   flag_simul         = enable / disable real-time simulation (disable for faster decoding)
%
% DESCRIPTION:
%   Offline monitor of receiver operations: stream reading, data visualization
%   and output data saving. Simultaneous monitor of different receivers,
%   also including different protocols.

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
%  Contributors:     Ivan Reguzzoni
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


% global COMportR
global rover
global order
global n_sys

num_sat = 32;

%------------------------------------------------------
% read protocol parameters
%------------------------------------------------------

nrec = length(protocol);
prot_par = cell(nrec,1);

for r = 1 : nrec
    if (protocol(r) == 0)
        prot_par{r} = param_ublox;
    elseif (protocol(r) == 1)
        prot_par{r} = param_fastrax;
    elseif (protocol(r) == 2)
        prot_par{r} = param_skytraq;
    elseif (protocol(r) == 3)
        prot_par{r} = param_nvs;
    end
end

%------------------------------------------------------
% initialization
%------------------------------------------------------

Eph = cell(nrec,1);
iono = cell(nrec,1);

for r = 1 : nrec

    % ephemerides
    Eph{r} = zeros(33,num_sat);

    % ionosphere parameters
    iono{r} = zeros(8,1);
end

%------------------------------------------------------
% data file creation
%------------------------------------------------------

fid_rover = cell(nrec,1);
fid_obs = cell(nrec,1);
fid_eph = cell(nrec,1);
fid_nmea = cell(nrec,1);

for r = 1 : nrec

    recname = [prot_par{r}{1,1} num2str(r)];

    % rover binary stream (uint8)
    fid_rover{r} = fopen([filerootOUT '_' recname '_rover_00.bin'],'w+');

    % input observations
    %   time_GPS --> double, [1,1]  --> zeros(1,1)
    %   time_M   --> double, [1,1]  --> zeros(1,1)
    %   time_R   --> double, [1,1]
    %   pr_M     --> double, [num_sat,1] --> zeros(num_sat,1)
    %   pr_R     --> double, [num_sat,1]
    %   ph_M     --> double, [num_sat,1] --> zeros(num_sat,1)
    %   ph_R     --> double, [num_sat,1]
    %   snr_M    --> double, [num_sat,1] --> zeros(num_sat,1)
    %   snr_R    --> double, [num_sat,1]
    fid_obs{r} = fopen([filerootOUT '_' recname '_obs_00.bin'],'w+');

    % input ephemerides
    %   timeGPS  --> double, [1,1]  --> zeros(1,1)
    %   Eph      --> double, [33,num_sat]
    fid_eph{r} = fopen([filerootOUT '_' recname '_eph_00.bin'],'w+');

    %write number of satellites
    fwrite(fid_obs{r}, num_sat, 'int8');
    fwrite(fid_eph{r}, num_sat, 'int8');

    if (flag_var_dyn_model) | (flag_stopGOstop)
        %dynamical model
        %  order      --> int8,   [1,1]
        %  sigmaq_vE  --> double, [1,1] - not used
        %  sigmaq_vN  --> double, [1,1] - not used
        %  sigmaq_vU  --> double, [1,1] - not used
        %  sigmaq0    --> double, [1,1] - not used
        %  sigmaq0_N  --> double, [1,1] - not used
        fid_dyn{r} = fopen([filerootOUT '_' recname '_dyn_00.bin'],'w+');
    end

    % nmea sentences
    fid_nmea{r} = fopen([filerootOUT '_' recname '_NMEA.txt'],'wt');
end

%------------------------------------------------------
% creation of the rover connections
%------------------------------------------------------

rover = cell(nrec,1);
data_rover = cell(nrec,1);
pos_UBX = cell(nrec,1);

for r = 1 : nrec

    d = dir(fileIN);                                                     %file to be read
    if ~isempty(d)
        num_bytes = d.bytes;                                           %file size (number of bytes)
        f_rover = fopen(fileIN);                                         %file opening
        d_rover = fread(f_rover,num_bytes,'uint8');                    %file reading
        d_rover = dec2bin(d_rover,8);                                  %conversion in binary number (N x 8bits matrix)
        d_rover = d_rover';                                            %transposed (8bits x N matrix)
        d_rover = d_rover(:)';                                         %conversion into a string (8N bits vector)
        fclose(f_rover);                                               %file closing
    else
        return
    end
    data_rover{r} = d_rover;

    %----------------------------------------------------------------------------------------------
    % UBX MESSAGE HEADER
    %----------------------------------------------------------------------------------------------

    header1 = 'B5';      % header (hexadecimal value)
    header2 = '62';      % header (hexadecimal value)
    header3 = '02';      % header (hexadecimal value)
    header4 = '10';      % header (hexadecimal value)

    codeHEX = [header1 header2 header3 header4];  % initial hexadecimal stream
    codeBIN = dec2bin(hex2dec(codeHEX),num_sat);       % initial binary stream

    pos_UBX{r} = strfind(data_rover{r}, codeBIN); % message initial index
    pos_UBX{r} = [0 pos_UBX{r}];

%     % find a serial port object.
%     obj1 = instrfind('Type', 'serial', 'Port', COMportR{r}, 'Tag', '');

%     % if a serial object already exists, delete it before creating a new one
%     if ~isempty(obj1)
%         delete(obj1);
%     end

%     % serial object creation
%     rover{r} = serial (COMportR{r},'BaudRate',prot_par{r}{2,1});
%     set(rover{r},'InputBufferSize',prot_par{r}{3,1});
%     if (protocol(r) == 0)
%         set(rover{r},'FlowControl','hardware');
%         set(rover{r},'RequestToSend','on');
%     end
    rover{r} = fopen(fileIN,'r');

end

clear data_rover

%------------------------------------------------------
% set receiver configuration
%------------------------------------------------------

% for r = 1 : nrec
%
%     % u-blox configuration
%     if (protocol(r) == 0)
%
%         %visualization
%         fprintf('\n');
%         fprintf('CONFIGURATION (u-blox n.%d)\n',r);
%
%         % only one connection can be opened in writing mode
%         fopen(rover{r});
%
%         [rover{r}, reply_save] = configure_ublox(rover{r}, COMportR{r}, prot_par{r}, 1);
%
%         % temporary connection closure (for other receiver setup)
%         fclose(rover{r});
%
%     % fastrax configuration
%     elseif (protocol(r) == 1)
%
%         %visualization
%         fprintf('\n');
%         fprintf('CONFIGURATION (fastrax n.%d)\n',r);
%
%         % only one connection can be opened in writing mode
%         fopen(rover{r});
%
%         [rover{r}] = configure_fastrax(rover{r}, COMportR{r}, prot_par{r}, 1);
%
%         % temporary connection closure (for other receiver setup)
%         fclose(rover{r});
%
%     % skytraq configuration
%     elseif (protocol(r) == 2)
%
%         %visualization
%         fprintf('\n');
%         fprintf('CONFIGURATION (skytraq n.%d)\n',r);
%
%         % only one connection can be opened in writing mode
%         fopen(rover{r});
%
%         [rover{r}] = configure_skytraq(rover{r}, COMportR{r}, prot_par{r}, 1);
%
%         % temporary connection closure (for other receiver setup)
%         fclose(rover{r});
%     end
% end

%------------------------------------------------------
% open rover connections
%------------------------------------------------------

for r = 1 : nrec
    fopen(rover{r});
end

%------------------------------------------------------
% absolute time startup
%------------------------------------------------------

tic;

%------------------------------------------------------
% log file initialization
%------------------------------------------------------

delete([filerootOUT '_log.txt']);
diary([filerootOUT '_log.txt']);
diary on

%--------------------------------------------------------
% data reading and saving
%--------------------------------------------------------

%visualization
fprintf('\n');
fprintf('ACQUISITION-PHASE\n');

%counter initialization
t = zeros(nrec,1);

%loop control initialization
f1 = figure;
s1 = get(0,'ScreenSize');
if (~flag_var_dyn_model)
    set(f1, 'position', [s1(3)-240-20 s1(4)-80-40 240 80], 'menubar', 'none', 'name', 'ROVER monitor');
    h1 = uicontrol(gcf, 'style', 'pushbutton', 'position', [80 20 80 40], 'string', 'STOP', ...
        'callback', 'setappdata(gcf, ''run'', 0)');
elseif (flag_stopGOstop)
    set(f1, 'position', [s1(3)-240-20 s1(4)-100-40 240 100], 'menubar', 'none', 'name', 'ROVER monitor');
    h1 = uicontrol(gcf, 'style', 'pushbutton', 'position', [80 20 80 40], 'string', 'GO', ...
        'callback', 'setappdata(gcf, ''run'', 2)');
    h2 = uicontrol(gcf, 'style', 'text', 'position', [40 70 160 15], 'string', 'Current state: "STOP"');
    order = 1;
else
    set(f1, 'position', [s1(3)-240-40 s1(4)-80-140 240 130], 'menubar', 'none', 'name', 'ROVER monitor');
    % Create the button group.
    h1 = uibuttongroup(gcf, 'visible','on');
    % Create three radio buttons in the button group.
    u0 = uicontrol(gcf, 'style', 'pushbutton', 'position', [10 10 50 30], 'string', 'STOP', ...
        'parent', h1,'callback', 'setappdata(gcf, ''run'', 0)'); %#ok<NASGU>
    u1 = uicontrol(gcf, 'Style','Radio','String','static',...
        'pos',[10 100 180 20],'parent', h1);
    u2 = uicontrol(gcf, 'Style','Radio','String','const. velocity dynamic',...
        'pos',[10 80 180 20],'parent', h1);
    u3 = uicontrol(gcf, 'Style','Radio','String','const. acceleration dynamic',...
        'pos',[10 60 180 20],'parent', h1);
end

flag = 1;
setappdata(gcf, 'run', flag);

if (flag_var_dyn_model) & (~flag_stopGOstop)
    if order == 1
        set(h1, 'SelectedObject', u1)
    elseif order == 2
        set(h1, 'SelectedObject', u2)
    else
        set(h1, 'SelectedObject', u3)
    end
end

%for Fastrax
tick_TRACK = 0;
%                   L1 freq    RF_conv*MCLK      MixerOffeset
correction_value = 1575420000 - 1574399750 - (3933/65536*16357400);
correction_value = correction_value * (1575420000/(1+1574399750));
doppler_count = 1;
delta = zeros(num_sat,1);
ph_R_old  = zeros(num_sat,1);
dop_R_old = zeros(num_sat,1);

%for SkyTraq
IOD_time = -1;

start_time = toc;

%infinite loop
while flag

    if (flag_stopGOstop)
        % mode management
        if (flag == 2) && (order ~= 2)                  % STOP --> GO
            order = 2;                                  % constant velocity model
            set(h1, 'string', 'STOP');                  % write STOP
            set(h1, 'callback', 'setappdata(gcf, ''run'', 1)');
            set(h2, 'string', 'Current state: "GO"');   % change current state
        elseif (flag == 1) && (order ~= 1)              % GO --> STOP
            order = 1;                                  % constant position model
            set(h1, 'string', 'END');                   % write END
            set(h1, 'callback', 'setappdata(gcf, ''run'', 0)');
            set(h2, 'string', 'Current state: "STOP"'); % change current state
        end
    end

    %time reading (relative to start_time)
    current_time = toc;

    for r = 1 : nrec

        if (length(pos_UBX{r}) == 1)
            break
        end

%         %serial port checking
%         rover_1 = get(rover{r},'BytesAvailable');
%         pause(0.05);
%         rover_2 = get(rover{r},'BytesAvailable');

        bits = pos_UBX{r}(2)-pos_UBX{r}(1);
        bytes = bits/8;
        pos_UBX{r}(1) = [];

        rover_1 = bytes;
        if (flag_simul), pause(1); end
        rover_2 = bytes;

        %test if the package writing is finished
        if (rover_1 == rover_2) & (rover_1 ~= 0)

            data_rover = fread(rover{r},rover_1,'uint8');     %serial port reading
            fwrite(fid_rover{r},data_rover,'uint8');          %transmitted stream save
            data_rover = dec2bin(data_rover,8);            %conversion to binary (N x 8bit matrix)
            data_rover = data_rover';                      %transpose (8bit x N matrix)
            data_rover = data_rover(:)';                   %conversion to string (8N bit vector)

            if (protocol(r) == 0)
                [cell_rover, nmea_sentences] = decode_ublox(data_rover);
            elseif (protocol(r) == 1)
                [cell_rover] = decode_fastrax_it03(data_rover);
                nmea_sentences = [];
            elseif (protocol(r) == 2)
                [cell_rover] = decode_skytraq(data_rover);
                nmea_sentences = [];
            elseif (protocol(r) == 3)
                %[cell_rover] = decode_nvs(data_rover);
                cell_rover = [];
                nmea_sentences = [];
            end

            %read data type
            type = '';

            %data type counters
            nRAW = 0;
            nEPH = 0;
            nHUI = 0;
            nTRACK  = 0;
            nTIM = 0;

            for i = 1 : size(cell_rover,2)

                %Tracking message data save (TRACK)
                if (strcmp(cell_rover{1,i},prot_par{r}{6,2}))

                    tick_TRACK    = cell_rover{2,i}(1);
                    phase_TRACK   = cell_rover{3,i}(:,6);
                    nTRACK = nTRACK + 1;

                    type = [type prot_par{r}{6,2} ' '];

                %Timing/raw message data save (RXM-RAW | PSEUDO)
                elseif (strcmp(cell_rover{1,i},prot_par{r}{1,2}))

                    time_R = cell_rover{2,i}(1);
                    week_R = cell_rover{2,i}(2);
                    ph_R   = cell_rover{3,i}(:,1);
                    pr_R   = cell_rover{3,i}(:,2);
                    dop_R  = cell_rover{3,i}(:,3);
                    snr_R  = cell_rover{3,i}(:,6);

                    %u-blox specific fields
                    if (protocol(r) == 0)
                        qual_R = cell_rover{3,i}(:,5);
                        lock_R = cell_rover{3,i}(:,7);
                        nRAW = nRAW + 1;
                    end

                    %Fastrax specific fields
                    if (protocol(r) == 1)
                        tick_PSEUDO = cell_rover{2,i}(4);
                        ObsFlags_R  = cell_rover{3,i}(:,5);
                        Corr_R      = cell_rover{3,i}(:,7);
                        LDO_R       = cell_rover{3,i}(:,8);
                        RangeEE_R   = cell_rover{3,i}(:,9); %#ok<NASGU>
                        RateEE_R    = cell_rover{3,i}(:,10); %#ok<NASGU>
                        EpochCount  = cell_rover{3,i}(:,11);
                        % Synchronize PSEUDO and TRACK
                        if (tick_PSEUDO == tick_TRACK)
                            %manage phase without code and phase correction
                            ph_R(abs(pr_R) > 0) = phase_TRACK(abs(pr_R) > 0) - correction_value*doppler_count;
                            doppler_count = doppler_count + 1;
                            delta = (ph_R_old - dop_R_old) - ph_R;
                            ph_R_old  = ph_R;
                            dop_R_old = dop_R;
                        else
                            ph_R = zeros(num_sat,1);
                        end
                        nRAW = nRAW + 1;
                    end

                    %manage phase without code
                    ph_R(abs(pr_R) == 0) = 0;

                    %manage "nearly null" data
                    ph_R(abs(ph_R) < 1e-100) = 0;

                    %counter increment
                    t(r) = t(r)+1;

                    %satellites with ephemerides available
                    satEph = find(sum(abs(Eph{r}))~=0);

                    %satellites with observations available
                    satObs = find(pr_R(:,1) ~= 0);

                    min_nsat_LS = 3 + n_sys;

                    %if all the visible satellites ephemerides have been transmitted
                    %and the total number of satellites is >= min_nsat_LS
                    if (ismember(satObs,satEph)) & (length(satObs) >= min_nsat_LS)

                        %data save
                        fwrite(fid_obs{r}, [0; 0; time_R; week_R; zeros(num_sat,1); pr_R; zeros(num_sat,1); ph_R; dop_R; zeros(num_sat,1); snr_R; zeros(3,1); iono{r}(:,1)], 'double');
                        fwrite(fid_eph{r}, [0; Eph{r}(:)], 'double');
                        if (flag_var_dyn_model) | (flag_stopGOstop)
                            fwrite(fid_dyn{r}, order, 'int8');
                        end
                    end

                    type = [type prot_par{r}{1,2} ' '];

                %Timing message data save (MEAS_TIME)
                elseif (strcmp(cell_rover{1,i},prot_par{r}{4,2}))

                    IOD_time = cell_rover{2,i}(1);
                    time_stq = cell_rover{2,i}(3);
                    week_stq = cell_rover{2,i}(2);

                    type = [type prot_par{r}{4,2} ' '];
                    nTIM = nTIM + 1;

                %Raw message data save (RAW_MEAS)
                elseif (strcmp(cell_rover{1,i},prot_par{r}{5,2}))

                    IOD_raw = cell_rover{2,i}(1);
                    if (IOD_raw == IOD_time)
                        time_R = time_stq;
                        week_R = week_stq;
                        pr_R = cell_rover{3,i}(:,3);
                        ph_R = cell_rover{3,i}(:,4);
                        snr_R = cell_rover{3,i}(:,2);
                        dop_R = cell_rover{3,i}(:,5);

                        %manage "nearly null" data
                        pr_R(abs(pr_R) < 1e-100) = 0;
                        ph_R(abs(ph_R) < 1e-100) = 0;

                        %manage phase without code
                        ph_R(abs(pr_R) == 0) = 0;

                        type = [type prot_par{r}{5,2} ' '];
                        nRAW = nRAW + 1;

                        %counter increment
                        t(r) = t(r)+1;

                        %satellites with ephemerides available
                        satEph = find(sum(abs(Eph{r}))~=0);

                        %satellites with observations available
                        satObs = find(pr_R(:,1) ~= 0);

                        %if all the visible satellites ephemerides have been transmitted
                        %and the total number of satellites is >= min_nsat_LS
                        if (ismember(satObs,satEph)) & (length(satObs) >= min_nsat_LS)

                            %data save
                            fwrite(fid_obs{r}, [0; 0; time_R; week_R; zeros(num_sat,1); pr_R; zeros(num_sat,1); ph_R; dop_R; zeros(num_sat,1); snr_R; zeros(3,1); iono{r}(:,1)], 'double');
                            fwrite(fid_eph{r}, [0; Eph{r}(:)], 'double');
                            if (flag_var_dyn_model) | (flag_stopGOstop)
                                fwrite(fid_dyn{r}, order, 'int8');
                            end
                        end
                    end

                %Hui message data save (AID-HUI)
                elseif (strcmp(cell_rover{1,i},prot_par{r}{3,2}))

                    %ionosphere parameters
                    iono{r}(:, 1) = cell_rover{3,i}(9:16);

                    if (nHUI == 0)
                        type = [type prot_par{r}{3,2} ' '];
                    end
                    nHUI = nHUI + 1;

                %Eph message data save (AID-EPH | FTX-EPH | GPS_EPH)
                elseif (strcmp(cell_rover{1,i},prot_par{r}{2,2}))

                    %satellite number
                    sat = cell_rover{2,i}(1);

                    if (~isempty(sat) & sat > 0)
                        Eph{r}(:, sat) = cell_rover{2,i}(:);
                    end

                    if (nEPH == 0)
                        type = [type prot_par{r}{2,2} ' '];
                    end
                    nEPH = nEPH + 1;

                end

            end

            if (~isempty(nmea_sentences))
                n = size(nmea_sentences,1);
                for i = 1 : n
                    fprintf(fid_nmea{r}, '%s', char(nmea_sentences(i,1)));
                end

                type = [type 'NMEA '];
            end

            %----------------------------------

            %visualization
            fprintf('\n');
            fprintf('---------------------------------------------------\n')
            fprintf([prot_par{r}{1,1} '(' num2str(r) ')' ': %7.4f sec (%4d bytes --> %4d bytes)\n'], current_time-start_time, rover_1, rover_2);
            fprintf('MSG types: %s\n', type);

            %visualization (Timing/raw information)
            if (nRAW > 0)
                sat_pr = find(pr_R ~= 0);       %satellites with code available
                sat_ph = find(ph_R ~= 0);       %satellites with phase available
                sat = union(sat_pr,sat_ph);     %satellites with code or phase available

                if (i < length(time_R)), fprintf(' DELAYED\n'); else fprintf('\n'); end
                fprintf('Epoch %3d:  GPStime=%d:%.3f (%d satellites)\n', t(r), week_R, time_R, length(sat));
                for j = 1 : length(sat)
                    if (protocol(r) == 0)
                        fprintf('   SAT %02d:  P1=%11.2f  L1=%12.2f  D1=%7.1f  QI=%1d  SNR=%2d  LOCK=%1d\n', ...
                            sat(j), pr_R(sat(j)), ph_R(sat(j)), dop_R(sat(j)), qual_R(sat(j)), snr_R(sat(j)), lock_R(sat(j)));
                    elseif (protocol(r) == 1)
                        % fprintf('   SAT %02d:  P1=%11.2f  L1=%12.2f  D1=%7.1f  QI=%1d  SNR=%2d  LOCK=%1d\n', ...
                        %     sat(j), pr_R(sat(j)), ph_R(sat(j)), dop_R(sat(j)),
                        %     qual_R(sat(j)), snr_R(sat(j)), lock_R(sat(j)));
                        fprintf('   SAT %02d:  P1=%11.2f  L1=%13.4f  D1=%7.1f  SNR=%2d  FLAG=%5d  CORR=%5d  LDO=%5d  ECnt=%6d Delta=%8.4f\n', ...
                            sat(j), pr_R(sat(j)), ph_R(sat(j)), dop_R(sat(j)), snr_R(sat(j)), ObsFlags_R(sat(j)), Corr_R(sat(j)), LDO_R(sat(j)), ...
                            EpochCount(sat(j)), delta(sat(j)));
                    elseif (protocol(r) == 2)
                        fprintf('   SAT %02d:  P1=%11.2f  L1=%12.2f  D1=%7.1f  SNR=%2d\n', ...
                            sat(j), pr_R(sat(j)), ph_R(sat(j)), dop_R(sat(j)), snr_R(sat(j)));
                    end
                end
            end

            %visualization (AID-HUI information)
            if (nHUI > 0)
                fprintf('Ionosphere parameters: ');
                if (sum(iono{r}) ~= 0)
                    fprintf('\n');
                    fprintf('    alpha0: %12.4E\n', iono{r}(1));
                    fprintf('    alpha1: %12.4E\n', iono{r}(2));
                    fprintf('    alpha2: %12.4E\n', iono{r}(3));
                    fprintf('    alpha3: %12.4E\n', iono{r}(4));
                    fprintf('    beta0 : %12.4E\n', iono{r}(5));
                    fprintf('    beta1 : %12.4E\n', iono{r}(6));
                    fprintf('    beta2 : %12.4E\n', iono{r}(7));
                    fprintf('    beta3 : %12.4E\n', iono{r}(8));
                else
                    fprintf('not sent\n');
                end
            end

            %visualization (AID-EPH | FTX-EPH | GPS_EPH information)
            if (nEPH > 0)
                sat = find(sum(abs(Eph{r}))>0);
                fprintf('Eph: ');
                for i = 1 : length(sat)
                    fprintf('%d ', sat(i));
                end
                fprintf('\n');
            end

            %poll a new ephemeris message every 10 epochs
%             if (mod(current_time-start_time,10) < 1)
%                 if (eph_polled == 0)
%                     if (protocol(r) == 0)
%                         ublox_poll_message(rover{r}, 'AID', 'EPH', 0);
%                         eph_polled = 1;
%                     elseif (protocol(r) == 2)
%                         skytraq_poll_message(rover{r}, '30', 0);
%                         eph_polled = 1;
%                     end
%                 end
%             else
%                 eph_polled = 0;
%             end
%
%             %wait for asynchronous write to finish
%             pause(0.1);
%
%             %poll a new AID-HUI message every 60 epochs
%             if (mod(current_time-start_time,60) < 1)
%                 if (hui_polled == 0)
%                     if (protocol(r) == 0)
%                         ublox_poll_message(rover{r}, 'AID', 'HUI', 0);
%                         hui_polled = 1;
%                     end
%                 end
%             else
%                 hui_polled = 0;
%             end
        end
    end

    %----------------------------------

    %test if the cycle execution has ended
    flag = getappdata(gcf, 'run');
    drawnow

    if (flag_var_dyn_model) & (~flag_stopGOstop)
        % check the changing of kalman filter model
        if get(h1, 'SelectedObject') == u1
            order = 1;
        elseif get(h1, 'SelectedObject') == u2
            order = 2;
        else
            order = 3;
        end
    end
end

%------------------------------------------------------
% close rover connections
%------------------------------------------------------

for r = 1 : nrec
    fclose(rover{r});
end

%------------------------------------------------------
% restore receiver original configuration
%------------------------------------------------------

% for r = 1 : nrec
%
%     % u-blox configuration
%     if (protocol(r) == 0)
%
%         %visualization
%         fprintf('\n');
%         fprintf('CONFIGURATION (u-blox n.%d)\n',r);
%
%         % only one connection can be opened in writing mode
%         fopen(rover{r});
%
%         % load u-blox saved configuration
%         if (reply_save)
%             fprintf('Restoring saved u-blox receiver configuration...\n');
%
%             reply_load = ublox_CFG_CFG(rover{r}, 'load');
%             tries = 0;
%
%             while (~reply_load)
%                 tries = tries + 1;
%                 if (tries > 3)
%                     disp('It was not possible to reload the receiver previous configuration.');
%                     break
%                 end
%                 reply_load = ublox_CFG_CFG(rover{r}, 'load');
%             end
%         end
%
%         % connection closure
%         fclose(rover{r});
%
%     end
% end

%------------------------------------------------------
% close files
%------------------------------------------------------

for r = 1 : nrec

    %data files closing
    fclose(fid_rover{r});
    fclose(fid_obs{r});
    fclose(fid_eph{r});
    fclose(fid_nmea{r});
    if (flag_var_dyn_model) || (flag_stopGOstop)
        fclose(fid_dyn{r});
    end
end

%log file closing
diary off

%------------------------------------------------------
% tasks at the end of the cycle
%------------------------------------------------------

%figure closing
close(f1);

%------------------------------------------------------
% RINEX conversion
%------------------------------------------------------

%dialog
selection = questdlg('Do you want to decode the binary streams and create RINEX files?',...
    'Request Function',...
    'Yes','No','Yes');
switch selection,
    case 'Yes',
        %visualization
        fprintf('\n');
        fprintf('RINEX CONVERSION\n');

        r = nrec;
        recname = [prot_par{r}{1,1} num2str(r)];
        gui_decode_stream([filerootOUT '_' recname], constellations);
end
