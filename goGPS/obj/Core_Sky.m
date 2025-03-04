classdef Core_Sky < handle
    % This class contains properties and methods to manage astronomical objects
    
    %--- * --. --- --. .--. ... * ---------------------------------------------
    %               ___ ___ ___
    %     __ _ ___ / __| _ | __|
    %    / _` / _ \ (_ |  _|__ \
    %    \__, \___/\___|_| |___/
    %    |___/                    v 0.5.1 beta 3
    %
    %--------------------------------------------------------------------------
    %  Copyright (C) 2009-2018 Mirko Reguzzoni, Eugenio Realini
    %  Written by: Giulio Tagliaferro
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
    
    properties
        time_ref_coord         % GPS Times of ephemerides
        time_ref_clock         %
        
        coord                  % Ephemerides [times x num_sat x 3]
        coord_type             % 0: Center of Mass 1: Antenna Phase Center
        clock                  % clocks of ephemerides [times x num_sat]
        
        coord_rate = 900;
        clock_rate = 900;
        
        iono                   % 16 iono parameters
        
        X_sun                  % coord of sun ephemerides ECEF at the same time of coord
        X_moon                 % coord of moon ephemerides ECEF at the same time of coord
        sun_pol_coeff          % coeff for polynoimial interpolation of tabulated sun positions
        moon_pol_coeff         % coeff for polynoimial interpolation of tabulated moon positions
        
        erp                    % Earth Rotation Parameters
        
        group_delays_flags = [ 'GC1C' ; 'GC1S' ; 'GC1L' ; 'GC1X' ; 'GC1P' ; 'GC1W' ; 'GC1Y' ; 'GC1M' ; 'GC2C' ; 'GC2D' ; 'GC2S' ; 'GC2L' ; 'GC2X' ; 'GC2P' ; 'GC2W' ; 'GC2Y' ; 'GC2M' ; 'GC5I' ; 'GC5Q' ; 'GC5X' ; ... % GPS codes
            'RC1C' ; 'RC1P' ; 'RC2C' ; 'RC2P' ; 'RC3I' ; 'RC3Q' ; 'RC3X' ; ...                                                                         % GLONASS code
            'EC1A' ; 'EC1B' ; 'EC1C' ; 'EC1X' ; 'EC1Z' ; 'EC5I' ; 'EC5Q' ; 'EC5X' ; 'EC7I' ; 'EC7Q' ; 'EC7X' ; 'EC8I' ; 'EC8Q' ; 'EC8X' ; 'EC6A'; 'EC6B'; 'EC6C'; 'EC6X'; 'EC6Z';...          % GALILEO codes
            'QC1C' ; 'QC1S' ; 'QC1L' ; 'QC1X' ; 'QC1Z' ; 'QC2S' ; 'QC2L' ; 'QC2X' ; 'QC2M' ; 'QC5I' ; 'QC5Q' ; 'QC5X' ; 'QC6S' ; 'QC6L' ; 'QC6X' ; ... % QZSS codes
            'BC2I' ; 'BC2Q' ; 'BC2X' ; 'BC7I' ; 'BC7Q' ; 'BC7X' ; 'BC6I' ; 'BC6Q' ; 'BC6X' ; ...                                                       % BeiDou codes
            'IC5A' ; 'IC5B' ; 'IC5C' ; 'IC5X' ; 'IC9A' ; 'IC9B' ; 'IC9C' ; 'IC9X' ; ...                                                                % IRNSS codes
            'SC1C' ; 'SC5I' ; 'SC5Q' ; 'SC5X' % SBAS
            ]; % ALL Rinex 3 code observations flags + first letter indicationg the constellation
        
        group_delays = zeros(32,82); % group delay of code measurements (meters) referenced to their constellation reference:
        %    GPS     -> Iono free linear combination C1P C2P
        %    GLONASS -> Iono free linear combination C1P C2P
        %    Galileo -> Iono free linear combination
        %    BedDou  -> Iono free linear combination
        %    QZS     -> Iono free linear combination
        %    IRNSS   -> Iono free linear combination
        %    SABS    -> Iono free linear combination
        group_delays_times           % 77x1 GPS_Time
        
        ant_pco               % satellites antenna phase center offset
        ant_pcv               % satellites antenna phase center variations
        
        avail                 % availability flag
        coord_pol_coeff       % coefficient of the polynomial interpolation for coordinates [11, 3, num_sat, num_coeff_sets]
        
        wsb                   % widelane satellite biases (only cnes orbits)
        wsb_date              % widelane satellite biases time
    end
    
    properties (Access = private)
        log                   % logger handler
        state                 % state handler
        cc                    % constellation collector handler
    end
    
    methods
        % Creator
        function this = Core_Sky(force_clean)
            % Core object creator
            this.state = Core.getCurrentSettings();
            this.log = Logger.getInstance();
            this.cc = Core.getCurrentSettings().getConstellationCollector;
            this.ant_pco = zeros(1, this.cc.getNumSat(), 3);
            if nargin == 1 && force_clean
                this.clearOrbit();
            end
        end
    end      
    
    % =========================================================================
    %  METHODS
    % =========================================================================
    
    methods % Public Access
        
        function initSession(this, start_date, stop_date)
            % Load and precompute all the celestial parameted needed in a session delimited by an interval of dates
            % SYNTAX:
            %    this.initSession(this, start_date, stop_time)
            
            %%% load Epehemerids
            if nargin == 2
                stop_date = start_date.last();
                start_date = start_date.first();
            end
            if ~isempty(start_date)
                eph_f_name   = this.state.getEphFileName(start_date, stop_date);
                clock_f_name = this.state.getClkFileName(start_date, stop_date);
                clock_is_present = true;
                for i = 1:length(clock_f_name)
                    clock_is_present = clock_is_present && (exist(clock_f_name{i}, 'file') == 2);
                end
                clock_in_eph = isempty(setdiff(eph_f_name, clock_f_name)) || ~clock_is_present; %%% condition to be tested in differnet cases
                if isempty(this.time_ref_coord) || start_date < this.time_ref_coord
                    this.clearOrbit();
                else
                    to_clear_date = start_date.getCopy();
                    to_clear_date.addSeconds(-86400); % keep only one day before the first epoch
                    this.clearOrbit(to_clear_date);
                end
                
                if  instr(lower(eph_f_name{1}), '.sp3') || instr(lower(eph_f_name{1}), '.eph') || instr(lower(eph_f_name{1}), '.pre') % assuming all files have the same extensions
                    this.toCOM();
                    this.clearPolyCoeff();
                    this.clearSunMoon();
                    this.log.addMarkedMessage('Importing ephemerides...');
                    for i = 1:length(eph_f_name)
                        [~,name,ext] = fileparts(eph_f_name{i});
                        gps_time = getFileStTime([name ext]);
                        end_time = this.getLastEpochCoord();
                        if isempty(end_time) || isempty(gps_time) ||  gps_time > end_time
                            this.addSp3(eph_f_name{i}, clock_in_eph);
                        end
                        this.coord_type = 0; % center of mass
                    end
                else %% if not sp3 assume is a rinex navigational file
                    this.toAPC();
                    this.clearPolyCoeff();
                    this.clearSunMoon();
                    this.log.addMarkedMessage('Importing broadcast ephemerides...');
                    this.importBrdcs(eph_f_name,start_date, stop_date, clock_in_eph);
                    this.coord_type = 1; % antenna phase center
                end
                
                if this.state.isIonoKlobuchar
                    f_name = this.state.getIonoFileName(start_date, stop_date);
                    this.importIono(f_name{1});
                end
                
                if not(clock_in_eph)
                    this.log.addMarkedMessage('Importing satellite clock files...');
                    for i = 1:length(clock_f_name)
                        [~,name,ext] = fileparts(clock_f_name{i});
                        gps_time = getFileStTime([name ext]);
                        end_time = this.getLastEpochClock();
                        if isempty(end_time) || isempty(gps_time) ||  gps_time > end_time
                            this.addClk(clock_f_name{i});
                        end
                        
                    end
                end
                
                % load PCV
                this.log.addMarkedMessage('Loading antennas phase center variations');
                this.loadAntPCV(this.state.getAtxFile);
                % pass to antenna phase center if necessary
                if this.coord_type == 0
                    this.toAPC();
                end
                
                % load erp
                this.log.addMarkedMessage('Importing Earth Rotation Parameters');
                this.importERP(this.state.getErpFileName(start_date, stop_date),start_date);
                
                % load dcb
                this.log.addMarkedMessage('Importing Differential code biases');
                this.importDCB();
            end
        end
        
        function clearOrbit(this, gps_date)
            % clear the object of the data older than gps_date
            % SYNTAX: this.clearOrbit(gps_date)
            if nargin > 1
                this.clearCoord(gps_date);
                this.clearClock(gps_date);
                this.clearSunMoon();
            else
                this.clearCoord();
                this.clearClock();
                this.clearSunMoon();
            end
        end
        
        function clearCoord(this, gps_date)
            % DESCRIPTION: clear coord data, if date is provided clear
            % only data before that date
            if nargin > 1 && ~isempty(this.time_ref_coord)
                if this.time_ref_coord < gps_date
                    n_ep = min(floor((gps_date - this.time_ref_coord)/this.coord_rate), size(this.coord,1));
                    this.coord(1:n_ep,:,:)=[];
                    this.time_ref_coord.addSeconds(n_ep*this.coord_rate);
                    this.coord_pol_coeff = []; %!!! the coefficient have to been recomputed
                    
                    % deleate also sun e moon data
                    if not(isempty(this.X_sun))
                        this.X_sun(1:n_ep,:)=[];
                    end
                    if not(isempty(this.X_moon))
                        this.X_moon(1:n_ep,:)=[];
                    end
                    this.sun_pol_coeff = []; %!!! the coefficient have to been recomputed
                    this.moon_pol_coeff = []; %!!! the coefficient have to been recomputed
                    
                end
            else
                this.coord=[];
                this.time_ref_coord = [];
                this.coord_pol_coeff = [];
            end
        end
        
        function clearClock(this, gps_date)
            % DESCRIPTION: clear clock data , if date is provided clear
            % only data before that date
            if nargin > 1  && ~isempty(this.time_ref_clock)
                if this.time_ref_clock < gps_date
                    n_ep = min(floor((gps_date - this.time_ref_clock)/this.clock_rate), size(this.clock,1));
                    this.clock(1:n_ep,:)=[];
                    this.time_ref_clock.addSeconds(n_ep*this.clock_rate);
                    
                    
                end
            else
                this.clock=[];
                this.time_ref_clock = [];
                this.wsb = [];
                this.wsb_date = [];
            end
        end
        
        function clearSunMoon(this, gps_date)
            % DESCRIPTION: clear sun and moon data , if date is provided clear
            % only data before that date
            if nargin > 1
                if this.time_ref_coord > gps_date
                    n_ep = floor((gps_date - this.time_ref_coord)/this.coord_rate);
                    this.X_sun(1:n_ep,:)=[];
                    this.X_moon(1:n_ep,:)=[];
                    this.sun_pol_coeff = []; %!!! the coefficient have to been recomputed
                    this.moon_pol_coeff = []; %!!! the coefficient have to been recomputed
                end
            end
            this.X_sun = [];
            this.X_moon = [];
            this.sun_pol_coeff = [];
            this.moon_pol_coeff = [];
        end
        
        function clearPolyCoeff(this)
            % DESCRIPTION : clear the precomupetd poly coefficent
            this.coord_pol_coeff = [];
            this.sun_pol_coeff = [];
            this.moon_pol_coeff = [];
        end
        
        function orb_time = getCoordTime(this)
            % DESCRIPTION:
            % return the time of coordinates in GPS_Time (unix time)
            orb_time = this.time_ref_coord.getCopy();
            orb_time.toUnixTime();
            [r_u_t , r_u_t_f ] = orb_time.getUnixTime();
            
            dt = (this.coord_rate : this.coord_rate : (size(this.coord,1)-1)*this.coord_rate)';
            
            
            u_t = r_u_t + uint32(fix(dt));
            u_t_f =  r_u_t_f  + rem(dt,1);
            
            idx = u_t_f >= 1;
            
            u_t(idx) = u_t(idx) + 1;
            u_t_f(idx) = u_t_f(idx) - 1;
            
            idx = u_t_f < 0;
            
            u_t(idx) = u_t(idx) - 1;
            u_t_f(idx) = 1 + u_t_f(idx);
            
            orb_time.appendUnixTime(u_t , u_t_f);
        end
        
        function orb_time = getClockTime(this)
            % DESCRIPTION:
            % return the time of clock corrections in GPS_Time (unix time)
            orb_time = this.time_ref_clock.getCopy();
            orb_time.toUnixTime();
            
            [r_u_t , r_u_t_f ] = orb_time.getUnixTime();
            
            
            dt = (this.clock_rate : this.clock_rate : (size(this.clock,1)-1)*this.clock_rate)';
            
            
            u_t = r_u_t + uint32(fix(dt));
            u_t_f =  r_u_t_f  + rem(dt,1);
            
            idx = u_t_f >= 1;
            
            u_t(idx) = u_t(idx) + 1;
            u_t_f(idx) = u_t_f(idx) - 1;
            
            idx = u_t_f < 0;
            
            u_t(idx) = u_t(idx) - 1;
            u_t_f(idx) = 1 + u_t_f(idx);
            
            orb_time.appendUnixTime(u_t , u_t_f);
            
        end
        
        function time = getLastEpochClock(this)
            % return last epoch of clock
            if ~isempty(this.time_ref_clock)
                time = this.time_ref_clock.getCopy();
                time.addSeconds((size(this.clock, 1) - 1) * this.clock_rate);
            else
                time = [];
            end
        end
        
        function time = getLastEpochCoord(this)
            % return last epoch of coord
            if ~isempty(this.time_ref_coord)
                time = this.time_ref_coord.getCopy();
                time.addSeconds((size(this.coord, 1) - 1) * this.coord_rate);
            else
                time = [];
            end
        end
        
        function eclipsed = checkEclipseManouver(this, time)
            eclipsed = int8(zeros(time.length,size(this.coord,2)));
            
            
            XS = this.coordInterpolate(time);
            
            %satellite geocentric position
            XS_n = sqrt(sum(XS.^2,3,'omitnan'));
            
            XS = XS./repmat(XS_n,1,1,3);
            
            %sun geocentric position
            X_sun = this.sunMoonInterpolate(time, true);
            X_sun = rowNormalize(X_sun);
            
            %satellite-sun angle
            cosPhi = sum(XS.*repmat(permute(X_sun,[1 3 2]),1,size(XS,2),1),3);
            %threshold to detect noon/midnight maneuvers
            thr = 4.9*pi/180*ones(time.length,size(this.coord,2)); % if we do not know put a conservative value
            
            shadowCrossing = cosPhi < 0 & XS_n.*sqrt(1 - cosPhi.^2) < GPS_SS.ELL_A;
            
            if this.cc.isGpsActive
                for i = 1:32 % only gps implemented
                    sat_type = this.ant_pcv(i).sat_type;
                    
                    if (~isempty(strfind(sat_type,'BLOCK IIA')))
                        thr(:,i) = 4.9*pi/180; % maximum yaw rate of 0.098 deg/sec (Kouba, 2009)
                    elseif (~isempty(strfind(sat_type,'BLOCK IIR')))
                        thr(:,i) = 2.6*pi/180; % maximum yaw rate of 0.2 deg/sec (Kouba, 2009)
                        shadowCrossing(:,i) = false;  %shadow crossing affects only BLOCK IIA satellites in gps
                    elseif (~isempty(strfind(sat_type,'BLOCK IIF')))
                        thr(:,i) = 4.35*pi/180; % maximum yaw rate of 0.11 deg/sec (Dilssner, 2010)
                        shadowCrossing(:,i) = false;  %shadow crossing affects only BLOCK IIA satellites in gps
                    end
                end
            end
            %noon/midnight maneuvers affect all satellites
            noonMidnightTurn = acos(abs(cosPhi)) < thr;
            eclipsed(shadowCrossing) = 1;
            eclipsed(noonMidnightTurn) = 3;
        end
        
        function importEph(this, eph, t_st, t_end, step, clock)
            % SYNTAX:
            %   eph_tab.importEph(eph, t_st, t_end, sat, step)
            %
            % INPUT:
            %   eph         = ephemerids matrix
            %   t_st        = start_time
            %   t_end       = start_time
            %   sat         = available satellite indexes
            %
            % OUTPUT:
            %   XS      = satellite position at time in ECEF(time_rx) (X,Y,Z)
            %   VS      = satellite velocity at time in ECEF(time_tx) (X,Y,Z)
            %   dtS     = satellite clock error (vector)
            %
            % DESCRIPTION:
            
            if nargin < 5
                step = 900;
            end
            this.coord_rate = step;
            if clock
                this.clock_rate = step;
            end
            if nargin < 4 || t_end.isempty()
                t_end = t_st;
            end
            times = (t_st.getGpsTime -5*step) : step : (t_end.getGpsTime+5*step); %%% compute 5 step before and after the day to use for polynomila interpolation
            this.time_ref_coord = t_st.getCopy();
            this.time_ref_coord.toUnixTime();
            this.time_ref_coord.addSeconds(-5*step);
            if clock
                this.time_ref_clock = this.time_ref_coord.getCopy();
            end
            this.coord = zeros(length(times), this.cc.getNumSat,3 );
            this.clock = zeros ( length(times),this.cc.getNumSat);
            systems = unique(eph(31,:));
            for sys = systems
                sat = unique(eph(30,eph(31,:) == sys)); %% keep only satellite also present in eph
                i = 0;
                prg_idx = sat;%this.cc.getIndex(sys,sat); % get progressive index of given satellites
                t_dist_exced = false;
                for t = times
                    i = i + 1;
                    [this.coord(i,prg_idx,:), ~, clock_temp, t_d_e, bad_sat] = this.satellitePositions(t, sat, eph(:, eph(31,:) == sys)); %%%% loss of precision problem should be less tha 1 mm
                    if clock
                        this.clock(i,prg_idx) = clock_temp';
                    end
                    t_dist_exced = t_dist_exced || t_d_e;
                end
                if t_dist_exced
                    cc = Core.getState.getConstellationCollector();
                    [ss, prn] = cc.getSysPrn(bad_sat);
                    str = '';
                    for s = 1 : numel(ss)
                        str = sprintf('%s, %c%02d', str, ss(s), prn(s));
                    end
                    str = str(3:end);
                    this.log.addWarning(sprintf('Satellite position problem:\nOne of the time bonds (%s , %s)\nfor sat %s\nis too far from valid ephemerids \nPositions might be inaccurate ',t_st.toString(0),t_end.toString(0), str));
                end
            end
        end
        
        function importBrdcs(this, f_names, t_st, t_end, clock, step)
            if nargin < 6
                step = 900;
            end
            if nargin < 5
                clock = true;
            end
            if nargin < 4 || t_end.isempty()
                t_end = t_st;
            end
            if not(iscell(f_names))
                f_names = {f_names};
            end
            eph = [];
            for i = 1:length(f_names)
                [eph_temp, this.iono] = this.loadRinexNav(f_names{i},this.cc,0,0);
                eph = [eph eph_temp];
            end
            
            if not(isempty(eph))
                this.importEph(eph, t_st, t_end, step, clock);
            end
            %%% add TGD delay parameter
            for const = unique(eph(31,:))
                eph_const = eph(:,eph(31,:)==const);
                for s = unique(eph_const(1,:))
                    eph_sat = eph_const(:, eph_const(1,:) == s);
                    GD = eph_sat(28,1); % TGD change only every 3 months
                    
                    switch char(const)
                        case 'G'
                            idx_c1w = this.getGroupDelayIdx('GC1W');
                            idx_c2w = this.getGroupDelayIdx('GC2W');
                            this.group_delays(s,idx_c1w) = -GD * Core_Utils.V_LIGHT;
                            f = this.cc.getGPS().F_VEC; % frequencies
                            this.group_delays(s,idx_c2w) = - f(1)^2 / f(2)^2 * GD * Core_Utils.V_LIGHT;
                        case 'R'
                            idx_c1p = this.getGroupDelayIdx('RC1P');
                            idx_c2p = this.getGroupDelayIdx('RC2P');
                            this.group_delays(s,idx_c1p) = -GD * Core_Utils.V_LIGHT;
                            f = this.cc.getGLONASS().F_VEC; % frequencies
                            this.group_delays(s,idx_c2p) = - f(1)^2 / f(2)^2 * GD * Core_Utils.V_LIGHT;
                        case 'E'
                            idx_c1p = this.getGroupDelayIdx('EC1B');
                            idx_c2p = this.getGroupDelayIdx('EC5I');
                            this.group_delays(s,idx_c1p) = -GD * Core_Utils.V_LIGHT;
                            f = this.cc.getGalileo().F_VEC; % frequencies
                            this.group_delays(s,idx_c2p) = - f(1)^2 / f(2)^2 * GD * Core_Utils.V_LIGHT;
                            
                    end
                end
            end
        end
        
        function [XS,VS,dt_s, t_dist_exced, bad_sat] =  satellitePositions(this, time, sat, eph)
            
            % SYNTAX:
            %   [XS, VS] = satellite_positions(time_rx, sat, eph);
            %
            % INPUT:
            %   time_rx     = reception time
            %   sat         = available satellite indexes
            %   eph         = ephemeris
            %
            % OUTPUT:
            %   XS      = satellite position at time in ECEF(time_rx) (X,Y,Z)
            %   VS      = satellite velocity at time in ECEF(time_tx) (X,Y,Z)
            %   dtS     = satellite clock error (vector)
            %
            % DESCRIPTION:
            nsat = length(sat);
            
            XS = zeros(nsat, 3);
            VS = zeros(nsat, 3);
            
            
            dt_s = zeros(nsat, 1);
            t_dist_exced = false;
            bad_sat = [];
            for i = 1 : nsat
                
                k = find_eph(eph, sat(i), time, 86400);
                if not(isempty(k))
                    %compute satellite position and velocity
                    [XS(i,:), VS(i,:)] = this.satelliteOrbits(time, eph(:,k), sat(i), []);
                    dt_s(i) = sat_clock_error_correction(time, eph(:,k));
                    dt_s(i) = sat_clock_error_correction(time - dt_s(i), eph(:,k));
                else
                    t_dist_exced = true;
                    bad_sat = [bad_sat; sat(i)];
                end
                
            end
            
            
            %XS=XS';
        end
        
        function addSp3(this, filename_SP3, clock_flag)
            % SYNTAX:
            %   this.addSp3(filename_SP3, clock_flag)
            %
            % INPUT:
            %   filename_SP3 = name of sp3 file
            %   clock_flag   = load also clock? (optional, dafault = true)
            %
            % DESCRIPTION:
            % add satellite and clock postiion contained in the sp3 file to
            % the object if values are contiguos with the ones already in
            % the object add them, otherwise clear the object and add them
            % data that are alrady present are going to be overwritten
            
            if isempty(this.coord)
                empty_file = true;
            else
                empty_file = false;
            end
            if nargin <3
                clock_flag = true;
            end
            
            % SP3 file
            f_sp3 = fopen(filename_SP3,'r');
            
            if (f_sp3 == -1)
                this.log.addWarning(sprintf('No ephemerides have been found at %s', filename_SP3));
            else
                fnp = File_Name_Processor;
                this.log.addMessage(this.log.indent(sprintf('Opening file %s for reading', fnp.getFileName(filename_SP3))));
                
                txt = fread(f_sp3,'*char')';
                version = txt(2);
                fclose(f_sp3);
                
                % get new line separators
                nl = regexp(txt, '\n')';
                if nl(end) <  numel(txt)
                    nl = [nl; numel(txt)];
                end
                lim = [[1; nl(1 : end - 1) + 1] (nl - 1)];
                lim = [lim lim(:,2) - lim(:,1)];
                if lim(end,3) < 3
                    lim(end,:) = [];
                end
                % get end pf header
                % coord  rate
                coord_rate = cell2mat(textscan(txt(repmat(lim(2,1),1,11) + (26:36)),'%f'));
                % n epochs
                nEpochs = cell2mat(textscan(txt(repmat(lim(1,1),1,7) + (32:38)),'%f'));
                % find first epoch
                string_time = txt(repmat(lim(1,1),1,28) + (3:30));
                % convert the times into a 6 col time
                date = cell2mat(textscan(string_time,'%4f %2f %2f %2f %2f %10.8f'));
                % import it as a GPS_Time obj
                sp3_first_ep = GPS_Time(date, [], true);
                if this.coord_rate ~= coord_rate
                    if empty_file
                        this.coord_rate = coord_rate;
                    else
                        this.log.addWarning(['Coord rate not match: ' num2str(coord_rate)]);
                        return
                    end
                    
                end
                if clock_flag
                    this.clock_rate = coord_rate;
                end
                % checking overlapping and same correct syncro
                sp3_last_ep = sp3_first_ep.getCopy();
                sp3_last_ep.addSeconds(coord_rate*nEpochs);
                if ~empty_file
                    idx_first = (sp3_first_ep - this.time_ref_coord)/this.coord_rate;
                    idx_last = (sp3_last_ep - this.time_ref_coord)/this.coord_rate;
                    memb_idx = ismembertol([idx_first idx_last], -1 : (size(this.coord,1)+1) ); %check whether the extend of sp3 file intersect with the current data
                    if sum(memb_idx)==0
                        empty_file = true;
                        this.clearCoord(); %<---- if new sp3 does not match the already present data clear the data and put the new ones
                        %                         elseif sum(memb_idx)==2 %<--- case new data are already in the class, (this leave out the case wether only one epoch more would be added to the current data, extremely unlikely)
                        %                             return
                    end
                end
                %initlaize array size
                if empty_file
                    this.time_ref_coord = sp3_first_ep.getCopy();
                    if clock_flag
                        this.time_ref_clock = sp3_first_ep.getCopy();
                    end
                    this.coord = zeros(nEpochs, this.cc.getNumSat(),3);
                    if clock_flag
                        this.clock = zeros(nEpochs, this.cc.getNumSat());
                    end
                else
                    c_n_sat = size(this.coord,2);
                    if memb_idx(1) == true && memb_idx(2) == false
                        n_new_epochs = idx_last - size(this.coord, 1);
                        this.coord = cat(1,this.coord,zeros(n_new_epochs,c_n_sat,3));
                        if clock_flag
                            this.clock = cat(1,this.clock,zeros(n_new_epochs,c_n_sat));
                        end
                    elseif memb_idx(1) == false && memb_idx(2) == true
                        this.time_ref_coord = sp3_first_ep.getCopy();
                        if clock_flag
                            this.time_ref_clock = sp3_first_ep.getCopy();
                        end
                        n_new_epochs = -idx_first;
                        this.coord = cat(1,zeros(n_new_epochs,c_n_sat,3),this.coord);
                        if clock_flag
                            this.clock = cat(1,zeros(n_new_epochs,c_n_sat),this.clock);
                        end
                    end
                end
                %%%% read data
                %%% raed epochs
                t_line = find(txt(lim(:,1)) == '*');
                string_time = txt(repmat(lim(t_line,1),1,28) + repmat(3:30, length(t_line), 1))';
                % convert the times into a 6 col time
                date = cell2mat(textscan(string_time,'%4f %2f %2f %2f %2f %10.8f'));
                % import it as a GPS_Time obj
                sp3_times = GPS_Time(date, [], true);
                if version == 'a'
                    go_ids_s = this.cc.getGoIds();
                    go_ids_s = reshape(sprintf('%2d',go_ids_s),2,length(go_ids_s))';
                    
                end
                ant_ids = this.cc.getAntennaId;
                for i = 1 : length(ant_ids)
                    ant_id = ant_ids{i};
                     if version == 'a'
                         sat_line = find(txt(lim(:,1)) == 'P'  & txt(lim(:,1)+2) == go_ids_s(i,1)& txt(lim(:,1)+3) == go_ids_s(i,2));
                     else
                         sat_line = find(txt(lim(:,1)) == 'P' & txt(lim(:,1)+1) == ant_id(1) & txt(lim(:,1)+2) == ant_id(2)& txt(lim(:,1)+3) == ant_id(3));
                     end
                    if ~isempty((sat_line))
                        c_ep_idx = round((sp3_times - this.time_ref_coord) / this.coord_rate) +1; %current epoch index
                        this.coord(c_ep_idx,i,:) = cell2mat(textscan(txt(repmat(lim(sat_line,1),1,41) + repmat(5:45, length(sat_line), 1))','%f %f %f'))*1e3;
                        if clock_flag
                            text = txt(repmat(lim(sat_line,1),1,14) + repmat(46:59, length(sat_line), 1));
                            clock = cell2mat(textscan(text','%f'))/1e6;
                            clock(clock > 0.99) = nan;
                            this.clock(c_ep_idx,i) = clock;
                        end
                    else
                    end
                end
            end
            clear sp3_file;
            this.coord = zero2nan(this.coord);  %<--- nan is slow for the computation of the polynomial coefficents
        end
        
        function fillClockGaps(this)
            %DESCRIPTION: fill clock gaps linearly interpolating neighbour clocks
            for i = 1 : size(this.clock,2)
                if not(sum(this.clock(:,i),1) == 0)
                    empty_clk_idx = this.clock(:,i) == 0 | isnan(this.clock(:,i));
                    n_ep = size(this.clock,1);
                    if sum(empty_clk_idx) < n_ep && sum(empty_clk_idx) > 0
                        this.clock(empty_clk_idx,i) = nan;
                        for hole = find(empty_clk_idx)'
                            [idx_bf  ] = max((1 : hole)'   .* (this.clock(1 : hole ,i) ./this.clock(1 : hole ,i) ));
                            [idx_aft ] = min((hole : n_ep)'.* (this.clock(hole : n_ep ,i) ./this.clock(hole : n_ep ,i)));
                            if isnan(idx_bf)
                                this.clock(hole,i) =  this.clock(idx_aft,i);
                            elseif isnan(idx_aft)
                                this.clock(hole,i) =  this.clock(idx_bf,i);
                            else
                                this.clock(hole,i) = ((idx_aft - hole) * this.clock(idx_bf,i) + (hole - idx_bf) * this.clock(idx_aft,i)) / (idx_aft - idx_bf);
                            end
                        end
                    end
                end
            end
        end
        
        function addClk(this,filename_clk)
            % SYNTAX:
            %   eph_tab.addClk(filename_clk)
            %
            % INPUT:
            %   filename_clk = name of clk rinex file file (IMPORTANT:the method
            %   assume 1 day clock filen at 5s)
            %
            % DESCRIPTION:
            % add satellites  clock contained in the clk file to
            % the object if values are contiguos with the ones already in
            % the object add them, otherwise clear the object and add them
            % data that are alrady present are going to be overwritten
            f_clk = fopen(filename_clk,'r');
            [~, fname, ~] = fileparts(filename_clk);
            if (f_clk == -1)
                this.log.addWarning(sprintf('No clk files have been found at %s', filename_clk));
            else
                fnp = File_Name_Processor;
                this.log.addMessage(this.log.indent(sprintf('Opening file %s for reading', fnp.getFileName(filename_clk))));
                t0 = tic;
                if isempty(this.clock)
                    empty_clk = true;
                else
                    empty_clk = false;
                end
                
                % open RINEX observation file
                fid = fopen(filename_clk,'r');
                txt = fread(fid,'*char')';
                fclose(fid);
                
                % get new line separators
                nl = regexp(txt, '\n')';
                if nl(end) <  numel(txt)
                    nl = [nl; numel(txt)];
                end
                lim = [[1; nl(1 : end - 1) + 1] (nl - 1)];
                lim = [lim lim(:,2) - lim(:,1)];
                if lim(end,3) < 3
                    lim(end,:) = [];
                end
                
                % get end pf header
                eoh = strfind(txt,'END OF HEADER');
                eoh = find(lim(:,1) > eoh);
                eoh = eoh(1) - 1;
                if strcmp(fname(1:3),'grg') % if cnes orbit loas wsb values
                    wl_line = txt(lim(1:eoh,1)) == 'W' & txt(lim(1:eoh,1)+1) == 'L'& txt(lim(1:eoh,1)+60) == 'C' & txt(lim(1:eoh,1)+61) == 'O' & txt(lim(1:eoh,1)+62) == 'M';
                    wsb_date = GPS_Time(cell2mat(textscan(txt(lim(find(wl_line,1,'first'),1) + [8:33]),'%f %f %f %f %f %f')));
                    wsb_prn = sscanf(txt(bsxfun(@plus, repmat(lim(wl_line, 1),1,3), 4:6))',' %f ');
                    wsb_value = sscanf(txt(bsxfun(@plus, repmat(lim(wl_line, 1),1,15), 39:53))','%f');
                    wsb = zeros(1,this.cc.getGPS.N_SAT);
                    wsb(wsb_prn) = wsb_value;
                    this.wsb = [this.wsb ;wsb];
                    this.wsb_date = [this.wsb_date ;wsb_date];
                end
                sats_line = find(txt(lim(eoh+1:end,1)) == 'A' & txt(lim(eoh+1:end,1)+1) == 'S') + eoh;
                % clk rate
                clk_rate = [];
                % find first epoch
                string_time = txt(repmat(lim(sats_line(1),1),1,27) + [8:34]);
                % convert the times into a 6 col time
                date = cell2mat(textscan(string_time,'%4f %2f %2f %2f %2f %10.7f'));
                % import it as a GPS_Time obj
                file_first_ep = GPS_Time(date, [], true);
                % find sampling rate
                ant_ids = this.cc.getAntennaId;
                ant_code_list = txt(bsxfun(@plus, repmat(lim(sats_line,1),1,3), 3:5));
                ant_id_list = Core_Utils.code3Char2Num(ant_code_list);
                for i = 1 : length(ant_ids)
                    ant_id = Core_Utils.code3Char2Num(ant_ids{i});
                    sat_line = sats_line(ant_id_list == ant_id);
                    if not(isempty(sat_line))
                        n_ep_sat = length(sat_line);
                        string_time = txt(repmat(lim(sat_line,1),1,27) + repmat(8:34, n_ep_sat, 1))';
                        % convert the times into a 6 col time
                        %date = cell2mat(textscan(string_time,'%4f %2f %2f %2f %2f %10.7f'));
                        % import it as a GPS_Time obj
                        %sat_time = GPS_Time(date, [], true);
                        sat_time = GPS_Time(string_time);
                        
                        % initilize matrix
                        if isempty(clk_rate)
                            clk_rate = median(diff(sat_time.getGpsTime()));
                            if not(empty_clk) & clk_rate ~= this.clock_rate
                                this.log.addWarning('Clock rate in file different from one in Core_Sky\n Discarding old data\n');
                                this.clearClock();
                                empty_clk = true;
                                this.clock_rate = clk_rate;
                            end
                            if empty_clk
                                this.clock_rate = clk_rate;
                                this.time_ref_clock = file_first_ep;
                                [ref_week, ref_sow] =this.time_ref_clock.getGpsWeek();
                                
                                this.clock = zeros(86400 / this.clock_rate, this.cc.getNumSat());
                            else
                                
                                c_ep_idx = round((file_first_ep - this.time_ref_clock) / this.clock_rate) +1; % epoch index
                                if c_ep_idx < 1
                                    this.clock = [zeros(abs(c_ep_idx)+1,size(this.clock,2)); this.clock];
                                    this.time_ref_clock = file_first_ep;
                                    [ref_week, ref_sow] =this.time_ref_clock.getGpsWeek();
                                end
                                c_ep_idx = round((file_first_ep - this.time_ref_clock) / this.clock_rate) +1; % epoch index
                                if c_ep_idx + 86400/this.clock_rate -1 > size(this.clock,1)
                                    this.clock = [this.clock; zeros( c_ep_idx + 86400/this.clock_rate -1 - size(this.clock,1) ,size(this.clock,2)); ];
                                end
                            end
                        end
                        c_ep_idx = round((sat_time - this.time_ref_clock) / this.clock_rate) +1; % epoch index
                        this.clock(c_ep_idx,i) = sscanf(txt(bsxfun(@plus, repmat(lim(sat_line, 1),1,21), 38:58))','%f');
                    end
                end
                this.log.addMessage(sprintf('Parsing completed in %.2f seconds', toc(t0)), 100);
                this.log.newLine(100);
            end
        end
        
        function importERP(this, f_name, time)
            this.erp = this.loadERP(f_name, time.getGpsTime());
        end
        
        function [erp, found] = loadERP(this, filename, time)
            % SYNTAX:
            %   [erp, found] = loadERP(filename, time);
            %
            % INPUT:
            %   filename = erp filename (including path) [string]
            %   time = GPS time to identify the time range of interest [vector]
            %
            % OUTPUT:
            %   erp = struct containing erp data
            %   found = flag to check if the required file was found
            %
            % DESCRIPTION:
            %   Tool for loading .erp files: Earth rotation parameters.
            
            fnp = File_Name_Processor();
            found = 0;
            erp = [];
            MJD = [];
            Xpole = [];
            Ypole = [];
            UT1_UTC = [];
            LOD = [];
            Xrt = [];
            Yrt = [];
            for f = 1 : length(filename)
                this.log.addMessage(this.log.indent(sprintf('Opening file %s for reading', fnp.getFileName(filename{f}))));
                fid = fopen(filename{f},'rt');
                
                if fid == -1
                    return
                end
                
                l=fgetl(fid);
                i=1;
                
                %check version
                if ~strcmp(l, 'version 2')
                    %wrong version
                    fclose(fid);
                    return
                end
                
                while isempty(strfind(l,'  MJD'));
                    if l==-1
                        fclose(fid);
                        return
                    end
                    l=fgetl(fid);
                    i=i+1;
                end
                i=i+1;
                fseek(fid, 0, 'bof');
                
                % [MJD,Xpole,Ypole,UT1_UTC,LOD,Xsig,Ysig,UTsig,LODsig,Nr,Nf,Nt,Xrt,Yrt,Xrtsig,Yrtsig] = textread(filename,'%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f','delimiter',' ','headerlines', i);
                
                ERP_data = textscan(fid,'%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f','headerlines',i);
                
                if (isempty(ERP_data{1}))
                    fclose(fid);
                    return
                else
                    found = 1;
                end
                
                MJD = [MJD; ERP_data{1}]; %#ok<*AGROW>
                Xpole = [Xpole; ERP_data{2}];
                Ypole = [Ypole; ERP_data{3}];
                UT1_UTC = [UT1_UTC; ERP_data{4}];
                LOD = [LOD; ERP_data{5}];
                Xrt = [Xrt; ERP_data{13}];
                Yrt = [Yrt; ERP_data{14}];
                fclose(fid);
            end
            
            jd = MJD + 2400000.5;
            [gps_week, gps_sow, ~] = jd2gps(jd);
            [ERP_date] = gps2date(gps_week, gps_sow);
            [ERP_time] = weektow2time(gps_week, gps_sow ,'G');
            
            if ~any(ERP_time <= max(time) | ERP_time >= min(time))
                % no suitable epochs found in erp file
                erp = [];
                return
            end
            
            % assign erp values and compute rates (@ epoch of the first epoch of orbits
            % erp.t0 = min(time);
            
            %correct MJD with the length of day
            for i = 2 : length(ERP_time)
                ERP_time(i)=ERP_time(i)+(LOD(i-1)*0.1e-6);
            end
            
            erp.t = ERP_time;
            erp.Xpole = Xpole;
            erp.Ypole = Ypole;
            erp.Xrt = Xrt;
            erp.Yrt = Yrt;
            
            %coefficients of the IERS (2010) mean pole model
            t0 = 2000;
            cf_ante = [0   55.974   346.346; ...
                1   1.8243    1.7896; ...
                2  0.18413  -0.10729; ...
                3 0.007024 -0.000908];
            
            cf_post = [0   23.513   358.891; ...
                1   7.6141   -0.6287; ...
                2      0.0       0.0; ...
                3      0.0       0.0];
            
            idx_ante = find(ERP_date(:,1) <= 2010);
            idx_post = find(ERP_date(:,1)  > 2010);
            
            %computation of the IERS (2010) mean pole
            erp.meanXpole = zeros(size(erp.Xpole));
            erp.meanYpole = zeros(size(erp.Ypole));
            for d = 1 : 4
                if (~isempty(idx_ante))
                    erp.meanXpole(idx_ante) = erp.meanXpole(idx_ante) + (ERP_date(idx_ante,1) - t0).^cf_ante(d,1) .* cf_ante(d,2);
                    erp.meanYpole(idx_ante) = erp.meanYpole(idx_ante) + (ERP_date(idx_ante,1) - t0).^cf_ante(d,1) .* cf_ante(d,3);
                end
                
                if (~isempty(idx_post))
                    erp.meanXpole(idx_post) = erp.meanXpole(idx_post) + (ERP_date(idx_post,1) - t0).^cf_post(d,1) .* cf_post(d,2);
                    erp.meanYpole(idx_post) = erp.meanYpole(idx_post) + (ERP_date(idx_post,1) - t0).^cf_post(d,1) .* cf_post(d,3);
                end
            end
            
            erp.m1 =   erp.Xpole*1e-6 - erp.meanXpole*1e-3;
            erp.m2 = -(erp.Ypole*1e-6 - erp.meanYpole*1e-3);
        end
        
        function importDCB(this)
            dcb_name = this.state.getDcbFile();
            if iscell(dcb_name)
                dcb_name = dcb_name{1};
            end
            if instr(dcb_name,'CAS')
                this.importSinexDCB();
            else
                this.importCODEDCB();
            end
        end
        
        function importCODEDCB(this)
            state = Core.getCurrentSettings();
            
            [dcb] = load_dcb(this.state.getDcbDir(), double(this.time_ref_coord.getGpsWeek), this.time_ref_coord.getGpsTime, true, state.getCC);
            %%% assume that CODE dcb contains only GPS and GLONASS
            %GPS C1W - C2W
            idx_w1 =  this.getGroupDelayIdx('GC1W');
            idx_w2 =  this.getGroupDelayIdx('GC2W');
            p1p2 = dcb.P1P2.value(dcb.P1P2.sys == 'G');
            iono_free = this.cc.getGPS.getIonoFree();
            this.group_delays(dcb.P1P2.prn(dcb.P1P2.sys == 'G') , idx_w1) = iono_free.alpha2 *p1p2*Core_Utils.V_LIGHT*1e-9;
            this.group_delays(dcb.P1P2.prn(dcb.P1P2.sys == 'G') , idx_w2) = iono_free.alpha1 *p1p2*Core_Utils.V_LIGHT*1e-9;
            % GPS C1W - C1C
            idx_w1 =  this.getGroupDelayIdx('GC1C');
            idx_w2 =  this.getGroupDelayIdx('GC2D');
            p1c1 = nan(this.cc.getGPS.N_SAT,1);
            p1c1(dcb.P1C1.sys == 'G') = dcb.P1C1.value(dcb.P1C1.sys == 'G');
            prns = dcb.P1C1.prn(dcb.P1P2.sys == 'G');
            this.group_delays(prns(prns~=0) , idx_w1) = (iono_free.alpha2 *p1p2(prns~=0) + p1c1(prns~=0))*Core_Utils.V_LIGHT*1e-9;
            this.group_delays(prns(prns~=0) , idx_w2) = (iono_free.alpha1 *p1p2(prns~=0) + p1c1(prns~=0))*Core_Utils.V_LIGHT*1e-9; %semi codeless tracking
            %GLONASS C1P - C2P
            idx_w1 =  this.getGroupDelayIdx('RC1P');
            idx_w2 =  this.getGroupDelayIdx('RC2P');
            p1p2 = dcb.P1P2.value(dcb.P1P2.sys == 'R');
            iono_free = this.cc.getGLONASS.getIonoFree();
            this.group_delays(dcb.P1P2.prn(dcb.P1P2.sys == 'R') , idx_w1) = (iono_free.alpha2 *p1p2)*Core_Utils.V_LIGHT*1e-9;
            this.group_delays(dcb.P1P2.prn(dcb.P1P2.sys == 'R') , idx_w2) = (iono_free.alpha1 *p1p2)*Core_Utils.V_LIGHT*1e-9;
        end
        
        function importSinexDCB(this)
            %DESCRIPTION: import dcb in sinex format
            % IMPORTANT WARNING: considering only daily dcb, some
            % assumpotion on the structure of the file are maded, based on
            % CAS MGEX DCB files
            
            % open SINEX dcb file
            file_name = this.state.getDcbFile();
            % geteting object mean times
            time_st = this.time_ref_clock.getCopy();
            time_end = time_st.getCopy();
            time_st.addSeconds(this.clock_rate * (size(this.clock,1) /2) -1);
            time_end.addSeconds(this.clock_rate * (size(this.clock,1) /2) +1);
            fnp = File_Name_Processor();
            file_name = fnp.dateKeyRepBatch(file_name, time_st, time_end);
            file_name = file_name{1};
            
            if isempty(file_name)
                this.log.addWarning('No dcb file found');
                return
            end
            fid = fopen(file_name,'r');
            if fid == -1
                this.log.addWarning(sprintf('Core_Sky: File %s not found', file_name));
                return
            end
            this.log.addMessage(this.log.indent(sprintf('Opening file %s for reading', file_name)));
            txt = fread(fid,'*char')';
            fclose(fid);
            
            % get new line separators
            nl = regexp(txt, '\n')';
            if nl(end) <  numel(txt)
                nl = [nl; numel(txt)];
            end
            lim = [[1; nl(1 : end - 1) + 1] (nl - 1)];
            lim = [lim lim(:,2) - lim(:,1)];
            if lim(end,3) < 3
                lim(end,:) = [];
            end
            
            % get end of header
            eoh = strfind(txt,'*BIAS SVN_ PRN ');
            eoh = find(lim(:,1) > eoh);
            
            eoh = eoh(1) - 1;
            head_line = txt(lim(eoh,1):lim(eoh,2));
            svn_idx = strfind(head_line,'PRN') - 1;
            c1_idx = strfind(head_line,'OBS1') -1 ;
            c2_idx = strfind(head_line,'OBS2') -1 ;
            val_idx = strfind(head_line,'__ESTIMATED_VALUE____') - 1;
            std_idx = strfind(head_line,'_STD_DEV___') - 1;
            % removing header lines from lim
            lim(1:eoh, :) = [];
            
            % removing last two lines (check if it is a standard) from lim
            lim((end-1):end, :) = [];
            
            % removing non satellites related lines from lim
            sta_lin = txt(lim(:,1)+13) > 57 | txt(lim(:,1)+13) < 48; % Satellites have numeric PRNs
            lim(sta_lin,:) = [];
            
            % TODO -> remove dcb of epoch different from the current one
            % find dcb names presents
            fl = lim(:,1);
            
            tmp = [txt(fl+svn_idx)' txt(fl+svn_idx+1)' txt(fl+svn_idx+2)' txt(fl+c1_idx)' txt(fl+c1_idx+1)' txt(fl+c1_idx+2)' txt(fl+c2_idx)' txt(fl+c2_idx+1)' txt(fl+c2_idx+2)'];
            idx = repmat(fl+val_idx,1,20) + repmat([0:19],length(fl),1);
            dcb = sscanf(txt(idx)','%f');
            idx = repmat(fl+std_idx,1,11) + repmat([0:10],length(fl),1);
            dcb_std = sscanf(txt(idx)','%f');
            % between C2C C2W the std are 0 -> unestimated
            % as a temporary solution substitute all the zero stds with the mean of all the read stds (excluding zeros)
            bad_ant_id = []; % list of missing antennas in the DCB file
            dcb_std(dcb_std == 0) = mean(dcb_std(dcb_std ~= 0));
            ref_dcb_name_old = '';
            bad_sat_str = '';
            for s = 1 : this.cc.getNumSat()
                sys = this.cc.system(s);
                prn = this.cc.prn(s);
                ant_id = this.cc.getAntennaId(s);
                sat_idx = this.prnName2Num(tmp(:,1:3)) == this.prnName2Num(ant_id);
                if sum(sat_idx) == 0
                    bad_ant_id = [bad_ant_id; ant_id];
                else
                    sat_dcb_name = tmp(sat_idx,4:end);
                    sat_dcb = dcb(sat_idx);
                    sat_dcb_std = dcb_std(sat_idx);
                    ref_dcb_name = this.cc.getRefDCB(s);
                    %check if there is the reference dcb in the one
                    %provided by the external source
                    
                    
                    % Set up the desing matrix
                    sys_gd = this.group_delays_flags(this.group_delays_flags(:,1) == sys,2:4);
                    n_dcb = size(sat_dcb_name,1);
                    A = zeros(n_dcb,size(sys_gd,1));
                    for d = 1 : n_dcb
                        idx1 = this.prnName2Num(sys_gd)  == this.prnName2Num(sat_dcb_name(d,1:3));
                        A(d,idx1) =  1;
                        idx2 = this.prnName2Num(sys_gd)  == this.prnName2Num(sat_dcb_name(d,4:6));
                        A(d,idx2) = -1;
                    end
                    % find not present gd
                    connected = sum(abs(A)) > 0;
                    A = A(:,connected);
                    W = diag(1./sat_dcb_std.^2);
                    % set the refernce iono-free combination to zero using lagrange multiplier
                   
                    if sum(sum(sat_dcb_name == repmat(ref_dcb_name,n_dcb,1),2) == 6) > 0 || sum(sum(sat_dcb_name == repmat([ref_dcb_name(4:6) ref_dcb_name(1:3)],n_dcb,1),2) == 6) > 0
                        
                        iono_free = this.cc.getSys(sys).getIonoFree();
                        if sys == 'E' && (size(A,2)-1) > rank(A) % special case galaile Q and X tracking are not connected
                            const = zeros(2,size(A,2));
                            ref_col1 = this.prnName2Num(sys_gd(connected,:))  == this.prnName2Num(ref_dcb_name(1:3));
                            const(1,ref_col1) = iono_free.alpha1;
                            ref_col2 = this.prnName2Num(sys_gd(connected,:))  == this.prnName2Num(ref_dcb_name(4:6));
                            const(1,ref_col2) = - iono_free.alpha2;
                            ref_col1 = this.prnName2Num(sys_gd(connected,:))  == this.prnName2Num('C1X');
                            const(2,ref_col1) = iono_free.alpha1;
                            ref_col2 = this.prnName2Num(sys_gd(connected,:))  == this.prnName2Num('C5X');
                            const(2,ref_col2) = - iono_free.alpha2;
                            N = [ A'*W*A  const'; const zeros(2)];
                            gd = N \ ([A'* W * sat_dcb; zeros(2,1)]);
                            gd(end-1:end) = []; %taking off lagrange multiplier
                        else
                            const = zeros(1,size(A,2));
                            ref_col1 = this.prnName2Num(sys_gd(connected,:))  == this.prnName2Num(ref_dcb_name(1:3));
                            const(ref_col1) = iono_free.alpha1;
                            ref_col2 = this.prnName2Num(sys_gd(connected,:))  == this.prnName2Num(ref_dcb_name(4:6));
                            const(ref_col2) = - iono_free.alpha2;
                            N = [ A'*W*A  const'; const 0];
                            gd = N \ ([A'* W * sat_dcb; 0]);
                            gd(end) = []; %taking off lagrange multiplier
                        end
                    else
                        % Save sat DCB problem string
                        if isempty(bad_sat_str)
                            bad_sat_str = sprintf(' - %s for %c%d', ref_dcb_name, sys, prn);
                        elseif strcmp(ref_dcb_name, ref_dcb_name_old)
                            bad_sat_str = sprintf('%s, %c%d', bad_sat_str, sys, prn);
                        else
                            bad_sat_str = sprintf('%s\n%s for %c%d', bad_sat_str, ref_dcb_name, sys, prn);
                        end
                        ref_dcb_name_old = ref_dcb_name;
                        
                        % deal with the problem (by hiding warnings)
                        const = zeros(2,size(A,2));
                        ref_col1 = this.prnName2Num(sys_gd(connected,:))  == this.prnName2Num(ref_dcb_name(1:3));
                        const(1,ref_col1) = 1;
                        ref_col2 = this.prnName2Num(sys_gd(connected,:))  == this.prnName2Num(ref_dcb_name(4:6));
                        const(2,ref_col2) =1;
                        N = [ A'*W*A  const'; const zeros(2)];
                        warning('off'); % Sometimes the system could be singular
                        gd = N \ ([A'* W * sat_dcb; zeros(2,1)]);
                        warning('on');
                        gd(end-1:end) = []; % t aking off lagrange multiplier
                    end
                    if sum(isnan(gd)) > 0 || sum(abs(gd) == Inf) > 0
                        this.log.addWarning('Invalid set of DCB ignoring them')
                    else
                        dcb_col   = strLineMatch(this.group_delays_flags,[repmat(sys,sum(connected),1) sys_gd(connected,:)]);
                        this.group_delays(prn, dcb_col) = - gd * Core_Utils.V_LIGHT * 1e-9;
                    end
                end
            end
            if ~isempty(bad_sat_str)
                this.log.addWarning(sprintf('One or more DCB are missing in "%s":\n%s\nthe bias will be eliminated only using iono-free combination', File_Name_Processor.getFileName(file_name), bad_sat_str));
            end
            if ~isempty(bad_ant_id)
                str = sprintf(', %c%c%c', bad_ant_id');
                if size(bad_ant_id, 1) > 1
                    this.log.addWarning(sprintf('Satellites %s not found in the DCB file', str(3 : end)));
                else
                    this.log.addWarning(sprintf('Satellites %s not found in the DCB file', str(3 : end)));
                end
            end
        end
        
        function idx = getGroupDelayIdx(this,flag)
            %DESCRIPTION: get the index of the gorup delay for the given
            %flag
            idx = find(sum(this.group_delays_flags == repmat(flag,size(this.group_delays_flags,1),1),2)==4);
        end
        
        function importIono(this,f_name)
            [~, this.iono, flag_return ] = this.loadRinexNav(f_name,this.cc,0,0);
            if (flag_return)
                return
            end
        end
        
        function [sx ,sy, sz] = getSatFixFrame(this, time, go_id)
            % SYNTAX:
            %   [i, j, k] = satellite_fixed_frame(time,X_sat);
            %
            % INPUT:
            %   time     = GPS_Time [nx1]
            %   X_sat    = postition of satellite [n_epoch x n-sat x 3]
            % OUTPUT:
            %   sx = unit vector that completes the right-handed system [n_epoch x n_sat x 3]
            %   sy = resulting unit vector of the cross product of k vector with the unit vector from the satellite to Sun [n_epoch x n_sat x 3]
            %   sz = unit vector pointing from the Satellite Mass Centre (MC) to the Earth's centre [n_epoch x n_sat x 3]
            %
            % DESCRIPTION:
            %   Computation of the unit vectors defining the satellite-fixed frame.
            
            
            t_sun = time;
            X_sun = this.sunMoonInterpolate(t_sun, true);
            if nargin > 2
                X_sat = this.coordInterpolate(time, go_id);
                X_sat = permute(X_sat,[1 3 2]);
            else
                X_sat = this.coordInterpolate(time);
            end
            n_sat = size(X_sat,2);
            sx = zeros(size(X_sat)); sy = sx; sz = sx;
            for idx = 1 : t_sun.length()
                x_sun = X_sun(idx,:);
                x_sat = X_sat(idx,:,:);
                e = permute(repmat(x_sun,1,1,n_sat),[1 3 2]) - x_sat ;
                e = e./repmat(normAlngDir(e,3),1,1,3); %sun direction
                k = -x_sat./repmat(normAlngDir(x_sat,3),1,1,3); %earth directions (z)
                j=cross(k,e); % perpendicular to bot earth and sun dorection (y)
                j= j ./ repmat(normAlngDir(j,3),1,1,3); % normalize, earth amd sun dorection are not perpendicular
                %                 j = [k(2).*e(3)-k(3).*e(2);
                %                     k(3).*e(1)-k(1).*e(3);
                %                     k(1).*e(2)-k(2).*e(1)];
                i=cross(j,k); %(x)
                %                 i = [j(2).*k(3)-j(3).*k(2);
                %                     j(3).*k(1)-j(1).*k(3);
                %                     j(1).*k(2)-j(2).*k(1)];
                sx(idx,:,:) = i ;
                sy(idx,:,:) = j ;
                sz(idx,:,:) = k ;
            end
            if n_sat == 1
                sx = squeeze(sx);
                sy = squeeze(sy);
                sz = squeeze(sz);
            end
            function nrm=normAlngDir(A,d)
                nrm=sqrt(sum(A.^2,d));
            end
        end
        
        function toCOM(this)
            %DESCRIPTION : convert coord to center of mass
            if ~isempty(this.coord)
                if this.coord_type == 0
                    return %already ceneter of amss
                end
                this.log.addMarkedMessage('Sat Ephemerids: switching to center of mass');
                this.COMtoAPC(-1);
                if isempty(this.coord_pol_coeff)
                    this.computeSatPolyCoeff(10, 11);
                end
                this.coord_type = 0;
            end
        end
        
        function coord = getCOM(this)
            if this.coord_type == 0
                coord = this.coord; %already ceneter of amss
            else
                [i, j, k] = this.getSatFixFrame(this.getCoordTime());
                sx = cat(3,i(:,:,1),j(:,:,1),k(:,:,1));
                sy = cat(3,i(:,:,2),j(:,:,2),k(:,:,2));
                sz = cat(3,i(:,:,3),j(:,:,3),k(:,:,3));
                coord = this.coord - cat(3, sum(repmat(this.ant_pco,size(this.coord,1),1,1) .* sx , 3) ...
                    , sum(repmat(this.ant_pco,size(this.coord,1),1,1) .* sy , 3) ...
                    , sum(repmat(this.ant_pco,size(this.coord,1),1,1) .* sz , 3));
            end
        end
        
        function toAPC(this)
            %DESCRIPTION : convert coord to center of antenna phase center
            if ~isempty(this.coord)
                if this.coord_type == 1
                    return %already antennna phase center
                end
                this.log.addMarkedMessage('Sat Ephemerids: switching to antenna phase center');
                this.COMtoAPC(1);
                if isempty(this.coord_pol_coeff)
                    this.computeSatPolyCoeff(10, 11);
                end
                this.coord_type = 1;
            end
        end
        
        function coord = getAPC(this)
            if this.coord_type == 1
                coord = this.coord; %already antennna phase center
            end
            [i, j, k] = this.getSatFixFrame(this.getCoordTime());
            sx = cat(3,i(:,:,1),j(:,:,1),k(:,:,1));
            sy = cat(3,i(:,:,2),j(:,:,2),k(:,:,2));
            sz = cat(3,i(:,:,3),j(:,:,3),k(:,:,3));
            coord = this.coord + cat(3, sum(repmat(this.ant_pco,size(this.coord,1),1,1) .* sx , 3) ...
                , sum(repmat(this.ant_pco,size(this.coord,1),1,1) .* sy , 3) ...
                , sum(repmat(this.ant_pco,size(this.coord,1),1,1) .* sz , 3));
            
        end
        
        function [wsb] = getWSB(this,time)
            [year_t, month_t, day_t ] = time.getCalEpoch();
            n_ep = size(this.wsb_date);
            n_ep = n_ep(1);
            wsb = 0;
            for i = 1:n_ep
                [year, month, day ] = this.wsb_date(i).getCalEpoch();
                if year == year_t && month == month_t && day == day_t
                    wsb = this.wsb(i,:);
                end
            end
        end
        
        function COMtoAPC(this, direction)
            [i, j, k] = this.getSatFixFrame(this.getCoordTime());
            sx = cat(3,i(:,:,1),j(:,:,1),k(:,:,1));
            sy = cat(3,i(:,:,2),j(:,:,2),k(:,:,2));
            sz = cat(3,i(:,:,3),j(:,:,3),k(:,:,3));
            this.coord = this.coord + sign(direction)*cat(3, sum(repmat(this.ant_pco, size(this.coord,1), 1, 1) .* sx , 3) ...
                , sum(repmat(this.ant_pco,size(this.coord,1),1,1) .* sy , 3) ...
                , sum(repmat(this.ant_pco,size(this.coord,1),1,1) .* sz , 3));
        end
        
        function pcv_delay = getPCV(this, band, ant_id, el, az)
            % DESCRIPTION: get the pcv correction for a given satellite and a given
            % azimuth and elevations using linear or bilinear interpolation
            
            pcv_delay = zeros(size(el));
            
            ant_names = reshape([this.ant_pcv.name]',3,size(this.ant_pcv,2))';
            
            ant_idx = sum(ant_names == repmat(ant_id,size(ant_names,1),1),2) == 3;
            sat_pcv = this.ant_pcv(ant_idx);
            
            freq = find(this.cc.getSys(ant_id(:,1)).CODE_RIN3_2BAND == num2str(band));
            if ~isempty(freq)
                freq = find(sat_pcv.frequency == freq); %%% check wether frequency in sat pcv are rinex 3 band or progressive number
            end
            
            if isempty(freq)
                this.log.addWarning(sprintf('No PCV model for %s frequency',[ant_id(:,1) band]),100);
                return
            end
            if this.coord_type == 0
                % if coordinates refers to center of mass apply also pco
                sat_pco = permute(this.ant_pco(:,ant_idx,:),[ 3 1 2]);
                neu_los = [cosd(az).*cosd(el) sind(az).*cosd(el) sind(el)];
                pco_delay = neu_los*sat_pco;
            else
                pco_delay = zeros(size(el));
            end
            %tranform el in zen
            zen = 90 - el;
            % get el idx
            zen_pcv = sat_pcv.tablePCV_zen;
            
            min_zen = zen_pcv(1);
            max_zen = zen_pcv(end);
            d_zen = (max_zen - min_zen)/length(zen_pcv);
            zen_float = (zen - min_zen)/d_zen + 1;
            zen_idx = min(max(floor((zen - min_zen)/d_zen) + 1 , 1),length(zen_pcv) - 1);
            d_f_r_el = min(max(zen_idx*d_zen - zen, 0)/ d_zen, 1) ;
            if nargin < 4 || isempty(sat_pcv.tablePCV_azi) % no azimuth change (satellites)
                pcv_val = sat_pcv.tableNOAZI(:,:,freq); % extract the right frequency
                %pcv_delay = pco_delay -  (d_f_r_el .* pcv_val(zen_idx)' + (1 - d_f_r_el) .* pcv_val(zen_idx + 1)');
                
                % Use polynomial interpolation to smooth PCV
                pcv_val = Core_Utils.interp1LS(1 : numel(pcv_val), pcv_val, min(8,numel(pcv_val)), zen_float);
                pcv_delay = pco_delay - pcv_val;
            else
                pcv_val = sat_pcv.tablePCV(:,:,freq); % extract the right frequency (receivers)
                this.log.addWarning('Do you have PCV values for satellites that depend on az?\n Copy here the implementation of getPCV in Receiver');
                %find azimuth indexes
                az_pcv = sat_pcv.tablePCV_azi;
                min_az = az_pcv(1);
                max_az = az_pcv(end);
                d_az = (max_az - min_az)/(length(az_pcv)-1);
                az_idx = min(max(floor((az - min_az)/d_az) + 1, 1),length(az_pcv) - 1);
                d_f_r_az = min(max(az - (az_idx-1)*d_az, 0)/d_az, 1);
                
                %interpolate along zenital angle
                idx1 = sub2ind(size(pcv_val),az_idx,zen_idx);
                idx2 = sub2ind(size(pcv_val),az_idx,zen_idx+1);
                pcv_delay_lf =  d_f_r_el .* pcv_val(idx1) + (1 - d_f_r_el) .* pcv_val(idx2);
                idx1 = sub2ind(size(pcv_val),az_idx+1,zen_idx);
                idx2 = sub2ind(size(pcv_val),az_idx+1,zen_idx+1);
                pcv_delay1_rg = d_f_r_el .* pcv_val(idx1) + (1 - d_f_r_el) .* pcv_val(idx2);
                %interpolate alogn azimtuh
                pcv_delay = pco_delay - (d_f_r_az .* pcv_delay_lf + (1 - d_f_r_az) .* pcv_delay1_rg);
            end
        end
        
        function [dts] = clockInterpolate(this, time, sat_in)
            % SYNTAX:
            %   [dt_S_SP3] = interpolate_SP3_clock(time, sat);
            %
            % INPUT:
            %   time  = interpolation timespan GPS_Time
            %   SP3   = structure containing precise ephemeris data
            %   sat   = satellite PRN
            %
            % OUTPUT:
            %   dt_S_SP3  = interpolated clock correction
            %
            % DESCRIPTION:
            %   SP3 (precise ephemeris) clock correction linear interpolation.
            if nargin < 3
                sat_in = this.cc.index;
            end
            
            for sat = sat_in(:)'
                interval = this.clock_rate;
                
                %find the SP3 epoch closest to the interpolation time
                %[~, p] = min(abs(SP3_time - time));
                % speed improvement of the above line
                % supposing SP3_time regularly sampled
                times = this.getClockTime();
                
                % find day change
                %date = times.get6ColDate;
                %day_change = find(diff(date(:,3)));
                
                p = max(1, min((round((time - this.time_ref_clock) / interval) + 1)', times.length - 1));
                
                b =  (times.getEpoch(p) - time)';
                
                SP3_c = zeros(time.length,2);
                u = zeros(time.length,1);
                
                % extract the SP3 clocks
                b_pos_idx = b > 0;
                p_pos = p(b_pos_idx);
                SP3_c(b_pos_idx,:) = cat(2, this.clock(p_pos - 1, sat), this.clock(p_pos, sat));
                u(b_pos_idx) = 1 - b(b_pos_idx)/interval;
                
                b_neg_idx = not(b_pos_idx);
                p_neg = p(b_neg_idx);
                SP3_c( b_neg_idx,:) = cat(2, this.clock(p_neg,sat), this.clock(p_neg+1,sat));
                u(b_neg_idx) = -b(b_neg_idx) / interval;
                
                dts_tmp = NaN * ones(size(SP3_c,1), size(SP3_c,2));
                idx = (sum(SP3_c ~= 0,2) == 2 .* ~any(SP3_c >= 0.999,2)) > 0;
                dts_tmp = (1-u) .* SP3_c(:,1) + (u) .* SP3_c(:,2);
                dts_tmp(not(idx)) = NaN;
                
                %             dt_S_SP3=NaN;
                %             if (sum(SP3_c~=0) == 2 && ~any(SP3_c >= 0.999))
                %
                %                 %linear interpolation (clock)
                %                 dt_S_SP3 = (1-u)*SP3_c(1) + u*SP3_c(2);
                %
                %                 %plot([0 1],SP3_c,'o',u,dt_S_SP3,'.')
                %                 %pause
                %             end
                if numel(sat_in) == 1
                    dts = dts_tmp(:);
                else
                    dts(:,sat) = dts_tmp(:);
                end
            end
            
        end
        
        function computeSatPolyCoeff(this, order, n_obs)
            % SYNTAX:
            %   this.computeSatPolyCoeff(degree, n_obs);
            %
            % INPUT:
            %
            % OUTPUT:
            %
            % DESCRIPTION: Precompute the coefficient of the N th poynomial for all the possible support sets
            if nargin == 1
                order = 10;
                n_obs = 11;
            end
            order = order + mod(order, 2); % order needs to be even
            n_obs = max(order + 1, n_obs); % minimum num of observations to use is == num of coefficients
            n_obs = n_obs + mod(n_obs + 1, 2); % n_obs needs to be odd
            
            n_coeff = order + 1;
            A = zeros(n_obs, n_coeff);
            A(:, 1) = ones(n_obs, 1);
            x = -((n_obs - 1) / 2) : ((n_obs - 1) / 2); % * this.coord_rate
            for i = 1 : order
                A(:, i + 1) = (x .^ i)';         % y = a + b*x + c*x^2
            end
            n_coeff_set = size(this.coord, 1) - n_obs + 1; %86400/this.coord_rate+1;
            n_sat = size(this.coord, 2);
            this.coord_pol_coeff = zeros(n_coeff, 3, n_sat, n_coeff_set);
            for s = 1 : n_sat
                for i = 1 : n_coeff_set
                    for j = 1 : 3
                        % this.coord_pol_coeff(: , j, s, i) = (A' * A) \ A' * squeeze(this.coord(i : i + n_obs - 1, s, j));
                        this.coord_pol_coeff(: , j, s, i) = A \ squeeze(this.coord(i : i + n_obs - 1, s, j));
                    end
                end
            end
        end
        
        function computeSat11PolyCoeff(this)
            % SYNTAX:
            %   this.computeSatPolyCoeff();
            %
            % INPUT:
            %
            % OUTPUT:
            %
            % DESCRIPTION: Precompute the coefficient of the 10th poynomial for all the possible support sets
            n_pol = 10;
            n_coeff = n_pol + 1;
            A = zeros(n_coeff, n_coeff);
            A(:, 1) = ones(n_coeff, 1);
            x = -5 : 5; % *this.coord_rat
            for i = 1 : 10
                A(:, i + 1) = (x .^ i)';
            end
            n_coeff_set = size(this.coord, 1) - 10; %86400/this.coord_rate+1;
            n_sat = size(this.coord, 2);
            this.coord_pol_coeff = zeros(n_coeff, 3, n_sat, n_coeff_set);
            for s = 1 : n_sat
                for i = 1 : n_coeff_set
                    for j = 1 : 3
                        this.coord_pol_coeff(: , j, s, i) = A \ squeeze(this.coord(i : i + 10, s, j));
                    end
                end
            end
        end
        
        function computeSMPolyCoeff(this)
            % SYNTAX:
            %   this.computeSatPolyCoeff();
            %
            % INPUT:
            %
            % OUTPUT:
            %
            % DESCRIPTION: Precompute the coefficient of the 10th poynomial for all the possible support sets
            n_pol = 10;
            n_coeff = n_pol+1;
            A = zeros(n_coeff, n_coeff);
            A(:, 1) = ones(n_coeff, 1);
            x = -5 : 5; % *this.coord_rat
            for i = 1 : 10
                A(:,i+1) = (x.^i)';
            end
            n_coeff_set = size(this.X_sun, 1) - 10;%86400/this.coord_rate+1;
            this.sun_pol_coeff = zeros(n_coeff, 3, n_coeff_set);
            this.moon_pol_coeff = zeros(n_coeff, 3, n_coeff_set);
            for i = 1 : n_coeff_set
                for j = 1 : 3
                    this.sun_pol_coeff(:,j,i) = A \ squeeze(this.X_sun(i:i+10,j));
                    this.moon_pol_coeff(:,j,i) = A \ squeeze(this.X_moon(i:i+10,j));
                end
            end
        end
        
        function [X_sat, V_sat] = coordInterpolate(this, t, sat)
            % SYNTAX:
            %   [X_sat] = Eph_Tab.polInterpolate(t, sat)
            %
            % INPUT:
            %    t = vector of times where to interpolate
            %    sat = satellite to be interpolated (optional)
            % OUTPUT:
            %
            % DESCRIPTION: interpolate coordinates of staellites
            if isempty(this.time_ref_coord)
                this.log.addWarning('Core_Sky appears to be empty, goGPS is going to miesbehave/nTrying to load needed data')
                this.initSession(t.first(), t.last())
            end
            n_sat = size(this.coord, 2);
            if nargin <3
                sat_idx = ones(n_sat, 1) > 0;
            else
                sat_idx = sat;
            end
            
            poly_order = 10;
            n_poly_obs = poly_order + 1;
            
            if isempty(this.coord_pol_coeff)
                this.computeSatPolyCoeff(poly_order, n_poly_obs);
            end
            
            n_sat = length(sat_idx);
            poly_order = size(this.coord_pol_coeff,1) - 1;
            n_border = ((size(this.coord, 1) - size(this.coord_pol_coeff, 4)) / 2);
            
            % Find the polynomial id at the interpolation time
            pid_floor = floor((t - this.time_ref_coord) / this.coord_rate) + 1 - n_border;
            pid_floor(pid_floor < 1) = 1;
            pid_floor(pid_floor > size(this.coord_pol_coeff, 4)) = size(this.coord_pol_coeff, 4);
            pid_ceil = ceil((t - this.time_ref_coord) / this.coord_rate) + 1 - n_border;
            pid_ceil(pid_ceil < 1) = 1;
            pid_ceil(pid_ceil > size(this.coord_pol_coeff, 4)) = size(this.coord_pol_coeff, 4);
            
            c_times = this.getCoordTime();
            c_times = c_times - this.time_ref_coord;
            t_diff = t - this.time_ref_coord;
            
            poly = permute(this.coord_pol_coeff(:,:,sat_idx, :),[1 3 2 4]);
            
            W_poly = zeros(t.length, 1);
            w = zeros(t.length, 1);
            X_sat = zeros(t.length, n_sat, 3);
            V_sat = zeros(t.length, n_sat, 3);
            for id = unique([pid_floor; pid_ceil])'
                % find the epochs with the same poly
                p_ids = find(pid_floor == id | pid_ceil == id);
                n_epoch = length(p_ids);
                t_fct = ones(n_epoch, poly_order + 1);
                t_fct(:,2) = (t_diff(p_ids) -  c_times(id + n_border))/this.coord_rate;
                for o = 3 : poly_order + 1
                    t_fct(:, o) = t_fct(:, o - 1) .* t_fct(:, 2);
                end
                w = 1 ./ t_fct(:,2) .^ 2;
                w(t_fct(:, 2) == 0, 1) = 1;
                W_poly(p_ids, 1) = W_poly(p_ids, 1) + w;
                w = repmat(w, 1, size(poly, 2), size(poly, 3));
                X_sat(p_ids, :,:) = X_sat(p_ids, :,:) + reshape(t_fct * reshape(poly(:,:,:, id), poly_order + 1, 3 * n_sat), n_epoch, n_sat, 3) .* w;
                for o = 2 : poly_order
                    t_fct(:, o) = o * t_fct(:, o);
                end
                V_sat(p_ids, :,:) = V_sat(p_ids, :,:) + (reshape(t_fct(:, 1 : poly_order) * reshape(poly(2 : end, :, :, id), poly_order, 3 * n_sat), n_epoch, n_sat, 3) / this.coord_rate) .* w;
            end
            X_sat = X_sat ./ repmat(W_poly, 1, n_sat, 3);
            V_sat = V_sat ./ repmat(W_poly, 1, n_sat, 3);
            
            if size(X_sat,2)==1
                X_sat = squeeze(X_sat);
                V_sat = squeeze(V_sat);
                if size(X_sat,2) == 1
                    X_sat = X_sat';
                    V_sat = V_sat';
                end
            end
        end
        
        function [X_sat, V_sat] = coordInterpolate11(this, t, sat)
            % SYNTAX:
            %   [X_sat] = Eph_Tab.polInterpolate11(t, sat)
            %
            % INPUT:
            %    t = vector of times where to interpolate
            %    sat = satellite to be interpolated (optional)
            % OUTPUT:
            %
            % DESCRIPTION: interpolate coordinates of staellites expressed with a Lagrange interpolator of degree 11
            n_sat = size(this.coord, 2);
            if nargin <3
                sat_idx = ones(n_sat, 1) > 0;
            else
                sat_idx = sat;
            end
            
            if isempty(this.coord_pol_coeff)
                this.computeSat11PolyCoeff();
            end
            n_sat = length(sat_idx);
            nt = t.length();
            %c_idx=round(t_fd/this.coord_rate)+this.start_time_idx;%coefficient set  index
            
            c_idx = round((t - this.time_ref_coord) / this.coord_rate) + 1 - ((size(this.coord, 1) - size(this.coord_pol_coeff, 4)) / 2);
            
            c_idx(c_idx < 1) = 1;
            c_idx(c_idx > size(this.coord_pol_coeff,4)) = size(this.coord_pol_coeff, 4);
            
            c_times = this.getCoordTime();
            % convert to difference from 1st time of the tabulated ephemerids (precise enough in the span of few days and faster that calaling method inside the loop)
            t_diff = t - this.time_ref_coord;
            c_times = c_times - this.time_ref_coord;
            %l_idx=idx-5;
            %u_id=idx+10;
            
            X_sat = zeros(nt,n_sat,3);
            V_sat = zeros(nt,n_sat,3);
            un_idx = unique(c_idx)';
            for id = un_idx
                t_idx = c_idx == id;
                times = t_diff(t_idx);
                t_fct =  (times -  c_times(id + ((size(this.coord, 1) - size(this.coord_pol_coeff, 4)) / 2)))/this.coord_rate;
                
                %%%% compute position
                t_fct2 = t_fct .* t_fct;
                t_fct3 = t_fct2 .* t_fct;
                t_fct4 = t_fct3 .* t_fct;
                t_fct5 = t_fct4 .* t_fct;
                t_fct6 = t_fct5 .* t_fct;
                t_fct7 = t_fct6 .* t_fct;
                t_fct8 = t_fct7 .* t_fct;
                t_fct9 = t_fct8 .* t_fct;
                t_fct10 = t_fct9 .* t_fct;
                eval_vec = [ones(size(t_fct)) ...
                    t_fct ...
                    t_fct2 ...
                    t_fct3 ...
                    t_fct4 ...
                    t_fct5 ...
                    t_fct6 ...
                    t_fct7 ...
                    t_fct8 ...
                    t_fct9 ...
                    t_fct10];
                X_sat(t_idx,:,:) = reshape(eval_vec*reshape(permute(this.coord_pol_coeff(:,:,sat_idx,id),[1 3 2 4]),11,3*n_sat),sum(t_idx),n_sat,3);
                %%% compute velocity
                eval_vec = [ ...
                    ones(size(t_fct))  ...
                    2*t_fct  ...
                    3*t_fct2 ...
                    4*t_fct3 ...
                    5*t_fct4 ...
                    6*t_fct5 ...
                    7*t_fct6 ...
                    8*t_fct7 ...
                    9*t_fct8 ...
                    10*t_fct9];
                V_sat(t_idx,:,:) = reshape(eval_vec*reshape(permute(this.coord_pol_coeff(2:end,:,sat_idx,id),[1 3 2 4]),10,3*n_sat),sum(t_idx),n_sat,3)/this.coord_rate;
            end
            if size(X_sat,2)==1
                X_sat = squeeze(X_sat);
                V_sat = squeeze(V_sat);
                if size(X_sat,2) ==1
                    X_sat = X_sat';
                    V_sat = V_sat';
                end
            end
        end
        
        function [sun_ECEF,moon_ECEF ] = sunMoonInterpolate(this, t, no_moon)
            % SYNTAX:
            %   [X_sat]=Eph_Tab.sunInterpolate(t,sat)
            %
            % INPUT:
            %    time = vector of times where to interpolate
            %    no_mmon = do not compute moon postion (default false)
            % OUTPUT:
            %
            % DESCRIPTION: interpolate sun and moon positions
            if isempty(this.X_moon) || isempty(this.X_sun)
                this.tabulateSunMoonPos();
            end
            
            if isempty(this.sun_pol_coeff)
                this.computeSMPolyCoeff();
            end
            
            if nargin < 3
                moon = true;
            else
                moon = not(no_moon);
            end
            %c_idx=round(t_fd/this.coord_rate)+this.start_time_idx;%coefficient set  index
            
            c_idx = round((t - this.time_ref_coord) / this.coord_rate) - 4;
            
            c_idx(c_idx<1) = 1;
            c_idx(c_idx > size(this.X_sun,1)-10) = size(this.X_sun,1)-10;
            
            c_times = this.getCoordTime();
            
            
            %l_idx=idx-5;
            %u_id=idx+10;
            nt = t.length();
            sun_ECEF=zeros(nt,3);
            if moon
                moon_ECEF=zeros(nt,3);
            end
            
            % convert to difference from 1st time of the tabulated ephemerids (precise enough in the span of few days and faster that calaling method inside the loop)
            t = t - this.time_ref_coord;
            c_times = c_times - this.time_ref_coord;
            
            un_idx=unique(c_idx)';
            for idx=un_idx
                t_idx=c_idx==idx;
                times=t(t_idx);
                %t_fct=((times-this.time(5+idx)))';%time from coefficient time
                t_fct =  (times -  c_times(idx+5))/this.coord_rate; %
                %%%% compute position
                t_fct2 = t_fct .* t_fct;
                t_fct3 = t_fct2 .* t_fct;
                t_fct4 = t_fct3 .* t_fct;
                t_fct5 = t_fct4 .* t_fct;
                t_fct6 = t_fct5 .* t_fct;
                t_fct7 = t_fct6 .* t_fct;
                t_fct8 = t_fct7 .* t_fct;
                t_fct9 = t_fct8 .* t_fct;
                t_fct10 = t_fct9 .* t_fct;
                eval_vec = [ones(size(t_fct)) ...
                    t_fct ...
                    t_fct2 ...
                    t_fct3 ...
                    t_fct4 ...
                    t_fct5 ...
                    t_fct6 ...
                    t_fct7 ...
                    t_fct8 ...
                    t_fct9 ...
                    t_fct10];
                sun_ECEF(t_idx,:) = eval_vec*reshape(this.sun_pol_coeff(:,:,idx),11,3);
                if moon
                    moon_ECEF(t_idx,:) = eval_vec*reshape(this.moon_pol_coeff(:,:,idx),11,3);
                end
            end
        end
        
        function [sun_ECEF , moon_ECEF] = computeSunMoonPos(this, time, no_moon)
            % SYNTAX:
            %   this.computeSunMoonPos(p_time)
            %
            % INPUT:
            %    time = Gps_Time [n_epoch x 1]
            %    no_moon = do not compute moon (Boolena deafult false)
            % OUTPUT:
            % sun_ECEF  : sun  coordinate Earth Centered Earth Fixed [n_epoch x 3]
            % moon_ECEF : moon coordinate Earth Centered Earth Fixed [n_epoch x 3]
            % DESCRIPTION: Compute sun and moon psitions at the time
            % desidered time
            
            global iephem km ephname inutate psicor epscor ob2000
            %time = GPS_Time((p_time(1))/86400+GPS_Time.GPS_ZERO);
            if nargin < 3
                moon = true;
            else
                moon = not(no_moon);
            end
            
            sun_id = 11; moon_id = 10; earth_id = 3;
            
            readleap; iephem = 1; ephname = 'de436.bin'; km = 1; inutate = 1; ob2000 = 0.0d0;
            
            tmatrix = j2000_icrs(1);
            
            setmod(2);
            % setdt(3020092e-7);
            setdt(5.877122033683494);
            xp = 171209e-6; yp = 414328e-6;
            
            go_dir = Core.getLocalStorageDir();
            
            %if the binary JPL ephemeris file is not available, generate it
            if (exist(fullfile(go_dir, 'de436.bin'),'file') ~= 2)
                fprintf('Warning: file "de436.bin" not found in at %s\n         ... generating a new "de436.bin" file\n',fullfile(go_dir, 'de436.bin'));
                fprintf('         (this procedure may take a while, but it will be done only once on each installation):\n')
                fprintf('-------------------------------------------------------------------\n\n')
                asc2eph(436, {'ascp01950.436', 'ascp02050.436'}, fullfile(go_dir, 'de436.bin'));
                fprintf('-------------------------------------------------------------------\n\n')
            end
            
            sun_ECEF = zeros(time.length(), 3);
            moon_ECEF = zeros(time.length(), 3);
            time = time.getCopy;
            time.toUtc;
            
            jd_utc = time.getJD;
            jd_tdb = time.getJDTDB; % UTC to TDB
            
            % precise celestial pole (disabled)
            %[psicor, epscor] = celpol(jd_tdb, 1, 0.0d0, 0.0d0);
            psicor = 0;
            epscor = 0;
            
            for e = 1 : time.length()
                % compute the Sun position (ICRS coordinates)
                rrd = jplephem(jd_tdb(e), sun_id, earth_id);
                sun_ECI = rrd(1:3);
                sun_ECI = tmatrix * sun_ECI;
                
                % Sun ICRS coordinates to ITRS coordinates
                deltat = getdt;
                jdut1 = jd_utc(e) - deltat;
                tjdh = floor(jdut1); tjdl = jdut1 - tjdh;
                sun_ECEF(e,:) = celter(tjdh, tjdl, xp, yp, sun_ECI)*1e3;
                
                if moon
                    % compute the Moon position (ICRS coordinates)
                    rrd = jplephem(jd_tdb(e), moon_id, earth_id);
                    moon_ECI = rrd(1:3);
                    moon_ECI = tmatrix * moon_ECI;
                    
                    % Moon ICRS coordinates to ITRS coordinates
                    deltat = getdt;
                    jdut1 = jd_utc(e) - deltat;
                    tjdh = floor(jdut1); tjdl = jdut1 - tjdh;
                    moon_ECEF(e,:) = celter(tjdh, tjdl, xp, yp, moon_ECI)*1e3;
                end
            end
        end
        
        function tabulateSunMoonPos(this)
            % SYNTAX:
            %   this.computeSunMoonPos(p_time)
            %
            % INPUT:
            %    p_time = Gps_Time [n_epoch x 1]
            % OUTPUT:
            % DESCRIPTION: Compute sun and moon positions at coordinates time and
            % store them in the object (Overwrite previous data)
            
            %his.t_sun = p_time;
            [this.X_sun , this.X_moon] = this.computeSunMoonPos(this.getCoordTime());
            this.computeSMPolyCoeff();
        end
                
        function loadAntPCV(this, filename_pcv)
            % Loading antenna's phase center variations and offsets
            fnp = File_Name_Processor();
            this.log.addMessage(this.log.indent(sprintf('Opening file %s for reading', fnp.getFileName(filename_pcv))));
            
            this.ant_pcv = Core_Utils.readAntennaPCV(filename_pcv, this.cc.getAntennaId(), this.time_ref_coord);
            this.ant_pco = zeros(1, this.cc.getNumSat(),3);
            %this.satType = cell(1,size(this.ant_pcv,2));
            if isempty(this.avail)
                this.avail = zeros(size(this.ant_pcv,2),1);
            end
            for sat = 1 : size(this.ant_pcv,2)
                if (this.ant_pcv(sat).n_frequency ~= 0)
                    this.ant_pco(:,sat,:) = this.ant_pcv(sat).offset(:,:,1);
                    %this.satType{1,sat} = this.ant_pcv(sat).sat_type;
                else
                    this.avail(sat) = 0;
                end
            end
        end
        
        function writeSP3(this, f_name, prec)
            % SYNTAX:
            %   eph_tab.writeSP3(f_name, prec)
            %
            % INPUT:
            %   f_name       = file name of the sp3 file to be written
            %   prec        = precision (cm) of satellite orbit for all
            %   satellites (default 100)
            %
            %
            % DESCRIPTION:
            %   Write the current satellite postions and clocks bias into a sp3
            %   file
            if nargin<3
                prec=99;
            end
            %%% check if clock rate and coord rate are compatible
            rate_ratio=this.coord_rate/this.clock_rate;
            if abs(rate_ratio-round(rate_ratio)) > 0.00000001
                this.log.addWarning(sprintf('Incompatible coord rate (%s) and clock rate (%s) , sp3 not produced',this.coord_rate,this.clock_rate))
                return
            end
            %%% check if sun and moon positions ahve been computed
            if isempty(this.X_sun) || this.X_sun(1,1)==0
                this.sun_moon_pos();
            end
            %%% compute center of mass position (X_sat - PCO)
            switch_back = false;
            if this.coord_type == 1
                this.toCOM();
                switch_back = true;
            end
            %%% write to file
            rate_ratio = round(rate_ratio);
            fid=fopen(f_name,'w');
            this.writeHeader(fid, prec);
            
            for i=1:length(this.coord)
                this.writeEpoch(fid,[squeeze(this.coord(i,:,:)/1000) this.clock((i-1)/rate_ratio+1,:)'*1000000],i); %% convert coord in km and clock in microsecodns
            end
            fprintf(fid,'EOF\n');
            fclose(fid);
            if switch_back
                this.toAPC();
            end
            
            
            
        end
        
        function writeHeader(this, fid, prec)
            
            if nargin<3
                %%% unknown precision
                prec=99;
            end
            %prec = num2str(prec);
            time=this.time_ref_coord.getCopy();
            str_time = time.toString();
            year = str2num(str_time(1:4));
            month = str2num(str_time(6:7));
            day = str2num(str_time(9:10));
            hour = str2num(str_time(12:13));
            minute = str2num(str_time(15:16));
            second = str2num(str_time(18:27));
            week = time.getGpsWeek();
            sow = time.getGpsTime()-week*7*86400;
            mjd = jd2mjd(cal2jd(year,month,day));
            d_frac = hour/24+minute/24*60+second/86400;
            step = this.coord_rate;
            num_epoch = length(this.time_ref_coord);
            cc = this.cc;
            fprintf(fid,'#cP%4i %2i %2i %2i %2i %11.8f %7i d+D   IGS14 CNV GReD\n',year,month,day,hour,minute,second,num_epoch);
            fprintf(fid,'## %4i %15.8f %14.8f %5i %15.13f\n',week,sow,step,mjd,d_frac);
            
            sats = [];
            pre = [];
            ids = cc.prn;
            for i = 1:length(ids)
                sats=[sats, strrep(sprintf('%s%2i', cc.system(i), ids(i)), ' ', '0')];
                pre=[pre, sprintf('%3i', prec)];
            end
            n_row=ceil(length(sats)/51);
            rows=cell(5,1);
            rows(:)={repmat('  0',1,17)};
            pres=cell(5,1);
            pres(:)={repmat('  0',1,17)};
            for i =1:n_row
                rows{i}=sats((i-1)*51+1:min(length(sats),i*51));
                pres{i}=pre((i-1)*51+1:min(length(pre),i*51));
            end
            last_row_length=length((i-1)*51+1:length(sats));
            rows{n_row}=[rows{n_row} repmat('  0',1,(51-last_row_length)/3)];
            pres{n_row}=[pres{n_row} repmat('  0',1,(51-last_row_length)/3)];
            
            fprintf(fid,'+   %2i   %s\n',sum(cc.n_sat),rows{1});
            for i=2:length(rows)
                fprintf(fid,'+        %s\n',rows{i});
            end
            for i=1:length(rows)
                fprintf(fid,'++       %s\n',pres{i});
            end
            fprintf(fid,'%%c M  cc GPS ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc\n');
            fprintf(fid,'%%c cc cc ccc ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc\n');
            fprintf(fid,'%%f  1.2500000  1.025000000  0.00000000000  0.000000000000000\n');
            fprintf(fid,'%%f  0.0000000  0.000000000  0.00000000000  0.000000000000000\n');
            fprintf(fid,'%%i    0    0    0    0      0      0      0      0         0\n');
            fprintf(fid,'%%i    0    0    0    0      0      0      0      0         0\n');
            fprintf(fid,'/* Produced using goGPS                                     \n');
            fprintf(fid,'/*                 Non                                      \n');
            fprintf(fid,'/*                     Optional                             \n');
            fprintf(fid,'/*                              Lines                       \n');
        end
        
        function writeEpoch(this,fid,XYZT,epoch)
            t = this.time_ref_coord.getCopy();
            t.addIntSeconds((epoch) * 900);
            cc = this.cc;
            str_time = t.toString();
            year = str2num(str_time(1:4));
            month = str2num(str_time(6:7));
            day = str2num(str_time(9:10));
            hour = str2num(str_time(12:13));
            minute = str2num(str_time(15:16));
            second = str2num(str_time(18:27));
            fprintf(fid,'*  %4i %2i %2i %2i %2i %11.8f\n',year,month,day,hour,minute,second);
            for i = 1:size(XYZT,1)
                fprintf(fid,'P%s%14.6f%14.6f%14.6f%14.6f\n',strrep(sprintf('%s%2i', cc.system(i), cc.prn(i)), ' ', '0'),XYZT(i,1),XYZT(i,2),XYZT(i,3),XYZT(i,4));
            end
            
        end
        
        function sys_c = getAvailableSys(this)
            % get the available system stored into the object
            % SYNTAX: sys_c = this.getAvailableSys()
            
            % Select only the systems present in the file
            sys_c = this.cc.getAvailableSys();
        end
    end
    
    % ==================================================================================================================================================
    %% STATIC FUNCTIONS used as utilities
    % ==================================================================================================================================================
    methods (Static, Access = public)
        
        function prn_num = prnName2Num(prn_name)
            % Convert a 4 char name into a numeric value (float)
            % SYNTAX:
            %   marker_num = markerName2Num(marker_name);
            
            prn_num = prn_name(:,1:3) * [2^16 2^8 1]';
        end
        
        function prn_name = prnNum2Name(prn_num)
            % Convert a numeric value (float) of a station into a 4 char marker
            % SYNTAX:
            %   marker_name = markerNum2Name(marker_num)
            prn_name = char(zeros(numel(prn_num), 3));
            prn_name(:,1) = char(floor(prn_num / 2^16));
            prn_num = prn_num - prn_name(:,1) * 2^16;
            prn_name(:,2) = char(floor(prn_num / 2^8));
            prn_num = prn_num - prn_name(:,2) * 2^8;
            prn_name(:,3) = char(prn_num);
        end
        
        function [eph, iono] = loadNavParameters(file_nav, cc)
            % SYNTAX:
            %   [eph, iono] = getNavParameters(file_nav, cc);
            %
            % INPUT:
            %   file_nav = RINEX navigation file
            %   cc = Constellation_Collector object, contains the satus of the satellite systems in use
            %
            % OUTPUT:
            %   Eph = matrix containing 33 navigation parameters for each satellite
            %   iono = matrix containing ionosphere parameters
            %
            % DESCRIPTION:
            %   Parse a RINEX navigation file.
            
            %  Partially based on RINEXE.M (EASY suite) by Kai Borre
            
            % ioparam = 0;
            eph = [];
            iono = zeros(8,1);
            
            
            %%
            % open RINEX observation file
            fid = fopen(file_nav,'r');
            txt = fread(fid,'*char')';
            % try to see if carriage return is present in the file (Windows stupid standard)
            % On Windows file lines ends with char(13) char(10)
            % instead of just using char(10)
            if ~isempty(find(txt(1:min(1000,numel(txt))) == 13, 1, 'first'))
                has_cr = true;  % The file has carriage return - I hate you Bill!
            else
                has_cr = false;  % The file is UNIX standard
            end
            % txt = txt(txt ~= 13);  % remove carriage return - I hate you Bill!
            fclose(fid);
            
            % get new line separators
            nl = regexp(txt, '\n')';
            if nl(end) <  (numel(txt) - double(has_cr))
                nl = [nl; numel(txt)];
            end
            lim = [[1; nl(1 : end - 1) + 1] (nl - 1 - double(has_cr))];
            lim = [lim lim(:,2) - lim(:,1)];
            while lim(end,3) < 3
                lim(end,:) = [];
            end
            
            % removing empty lines at end of file
            while (lim(end,1) - lim(end-1,1))  < 2
                lim(end,:) = [];
            end
            
            eoh = 0;
            flag_eoh = false;
            while eoh < size(lim, 1) && flag_eoh == false
                eoh = eoh + 1;
                flag_eoh = strcmp(txt((lim(eoh,1) + 60) : min(lim(eoh,1) + 72, lim(eoh, 2))), 'END OF HEADER');
            end
            
            % Reading Header
            head_field{1} = 'RINEX VERSION / TYPE';                  %  1
            head_field{2} = 'PGM / RUN BY / DATE';                   %  2
            head_field{3} = 'LEAP SECONDS';                          %  3
            head_field{4} = 'ION ALPHA';                             %  4
            head_field{5} = 'ION BETA';                              %  5
            
            % parsing ------------------------------------------------------------------------------------------------------------------------------------------
            
            % retriving the kind of header information is contained on each line
            line2head = zeros(eoh, 1);
            l = 0;
            while l < eoh
                l = l + 1;
                %DEBUG: txt((lim(l,1) + 60) : lim(l,2))
                tmp = find(strcmp(strtrim(txt((lim(l,1) + 60) : lim(l,2))), head_field));
                if ~isempty(tmp)
                    % if the field have been recognized (it's not a comment)
                    line2head(l) = tmp;
                end
            end
            
            % read RINEX type 3 or 2 ---------------------------------------------------------------------------------------------------------------------------
            
            l = find(line2head == 1);
            type_found = ~isempty(l);
            
            if type_found
                dataset = textscan(txt(lim(1,1):lim(1,2)), '%f%c%18c%c');
            else
                throw(MException('VerifyINPUTInvalidNavigationalFile', 'This navigational RINEX does not contain orbits'));
            end
            this.rin_type = dataset{1};
            this.rinex_ss = dataset{4};
            
            if dataset{2} == 'N'
                % Is a navigational file
            else
                throw(MException('VerifyINPUTInvalidNavigationalFile', 'This navigational RINEX does not contain orbits'));
            end
            
            % Read iono parameters (if found):
            
            [~, l_iono] = intersect(line2head, [4,5]);
            iono_found = numel(l_iono) == 2;
            iono_loaded = false;
            if iono_found
                data = textscan(txt(lim(l_iono(1),1) + (2 : 49)), '%f%f%f%f');
                if ~isempty(data{4})
                    iono(1) = data{1};
                    iono(2) = data{2};
                    iono(3) = data{3};
                    iono(4) = data{4};
                end
                data = textscan(txt(lim(l_iono(2),1) + (2 : 49)), '%f%f%f%f');
                if ~isempty(data{4})
                    iono(5) = data{1};
                    iono(6) = data{2};
                    iono(7) = data{3};
                    iono(8) = data{4};
                end
                iono_loaded = true;
            end
            
            if this.rin_type < 3 % at the moment the new reader support only RINEX 3 broadcast ephemeris
                [eph, iono] = RINEX_get_nav(file_nav, cc);
            else
                eph = [];
                for sys_c = cc.getActiveSysChar()
                    
                    id_ss = find(txt(lim(eoh:end,1)) == sys_c) + eoh - 1;
                    n_epo = numel(id_ss);
                    
                    switch sys_c
                        case 'G'
                            sys_index = cc.getGPS().getFirstId();
                            nppl = [4 4 4 4 4 4 4 2]; % number of parameters per line
                        case 'R'
                            sys_index = cc.getGLONASS().getFirstId();
                            nppl = [4 4 4 4];         % number of parameters per line
                        case 'E'
                            sys_index = cc.getGalileo().getFirstId();
                            full_line = median(lim(id_ss + 6 ,3)) > 65; % detect if all the lines have 79 chars (empty fields are filled with spaces)
                            nppl = [4 4 4 4 4 (3 + full_line) 4 1]; % number of parameters per line
                        case 'J'
                            sys_index = cc.getQZSS().getFirstId();
                            nppl = [4 4 4 4 4 4 4 2]; % number of parameters per line
                        case 'C'
                            sys_index = cc.getBeiDou().getFirstId();
                            nppl = [4 4 4 4 4 4 4 2]; % number of parameters per line
                        case 'I'
                            sys_index = cc.getIRNSS().getFirstId();
                            full_line = median(lim(id_ss + 6 ,3)) > 65; % detect if all the lines have 79 chars (empty fields are filled with spaces)
                            nppl = [4 4 4 4 4 (3 + full_line) (3 + full_line) 1]; % number of parameters per line
                        case 'S'
                            sys_index = cc.getSBAS().getFirstId();
                            nppl = [4 4 4 4];         % number of parameters per line
                    end
                    par_offset = [4 23 42 61]; % character offset for reading a parameter
                    lin_offset = [0 cumsum((nppl(1:end-1) * 19 + 5 + has_cr))]; % character offset for reading on a certain line
                    
                    % Function to extract a parameter from the broadcast info table
                    getParStr = @(r,c) txt(repmat(lim(id_ss,1),1,19) + par_offset(c) + lin_offset(r) + repmat(0:18, n_epo, 1));
                    getParNum = @(r,c) str2num(txt(repmat(lim(id_ss,1),1,19) + par_offset(c) + lin_offset(r) + repmat(0:18, n_epo, 1)));
                    
                    % Epochs
                    eph_ss = zeros(n_epo, 33);
                    eph_ss(:,  1) = str2num(txt(repmat(lim(id_ss,1), 1, 2) + repmat([1 2], length(id_ss), 1)));
                    
                    date = cell2mat(textscan(getParStr(1,1)','%4f %2f %2f %2f %2f %2f'));
                    time = GPS_Time(date, [], iif(sys_c == 'R', false, true));
                    
                    % Other parameters
                    if ismember(sys_c, 'RS')
                        eph_ss(:,  2) = -getParNum(1,2); % TauN
                        eph_ss(:,  3) = getParNum(1,3); % GammaN
                        eph_ss(:,  4) = getParNum(1,4); % tk
                        
                        eph_ss(:,  5) = 1e3 * getParNum(2,1); % X
                        eph_ss(:,  8) = 1e3 * getParNum(2,2); % Xv
                        eph_ss(:, 11) = 1e3 * getParNum(2,3); % Xa
                        eph_ss(:, 27) = getParNum(2,4); % Bn
                        
                        eph_ss(:,  6) = 1e3 * getParNum(3,1); % Y
                        eph_ss(:,  9) = 1e3 * getParNum(3,2); % Yv
                        eph_ss(:, 12) = 1e3 * getParNum(3,3); % Ya
                        eph_ss(:, 15) = getParNum(3,4); % freq_num
                        
                        eph_ss(:,  7) = 1e3 * getParNum(4,1); % Z
                        eph_ss(:, 10) = 1e3 * getParNum(4,2); % Zv
                        eph_ss(:, 13) = 1e3 * getParNum(4,3); % Za
                        eph_ss(:, 14) = getParNum(4,4); % E
                        
                        [week_toe, toe] = time.getGpsWeek;
                        eph_ss(:, 18) = toe;
                        eph_ss(:, 24) = week_toe;
                        eph_ss(:, 32) = double(week_toe) * 7 * 86400 + toe;
                        
                        eph_ss(:, 30) = eph_ss(:, 1) + (sys_index - 1); % go_id
                        eph_ss(:, 31) = int8(sys_c);
                    else % for GEJCI
                        eph_ss(:, 19) = getParNum(1,2); % af0
                        eph_ss(:, 20) = getParNum(1,3); % af1
                        eph_ss(:,  2) = getParNum(1,4); % af2
                        
                        eph_ss(:, 22) = getParNum(2,1); % IODE
                        eph_ss(:, 11) = getParNum(2,2); % crs
                        eph_ss(:,  5) = getParNum(2,3); % deltan
                        eph_ss(:,  3) = getParNum(2,4); % M0
                        
                        eph_ss(:,  8) = getParNum(3,1); % cuc
                        eph_ss(:,  6) = getParNum(3,2); % ecc
                        eph_ss(:,  9) = getParNum(3,3); % cus
                        eph_ss(:,  4) = getParNum(3,4); % roota
                        
                        eph_ss(:, 18) = getParNum(4,1); % toe
                        eph_ss(:, 14) = getParNum(4,2); % cic
                        eph_ss(:, 16) = getParNum(4,3); % Omega0
                        eph_ss(:, 15) = getParNum(4,4); % cis
                        
                        eph_ss(:, 12) = getParNum(5,1); % i0
                        eph_ss(:, 10) = getParNum(5,2); % crc
                        eph_ss(:,  7) = getParNum(5,3); % omega
                        eph_ss(:, 17) = getParNum(5,4); % Omegadot
                        
                        eph_ss(:, 13) = getParNum(6,1); % idot
                        eph_ss(:, 23) = getParNum(6,2); % code_on_L2
                        if (sys_c == 'C') % Beidou week have an offset of 1356 weeks
                            eph_ss(:, 24) = GPS_Time.GPS_BDS_WEEK0 + getParNum(6,3); % weekno
                        else
                            eph_ss(:, 24) = getParNum(6,3); % weekno
                        end
                        if ismember(sys_c, 'GJC') % present only for G,J,C constellations
                            eph_ss(:, 25) = getParNum(6,4); % L2flag
                        end
                        
                        eph_ss(:, 26) = getParNum(7,1); % svaccur
                        eph_ss(:, 27) = getParNum(7,2); % svhealth
                        eph_ss(:, 28) = getParNum(7,3); % tgd
                        
                        %eph_ss(:, xx) = getParNum(8,1); % tom
                        if ismember(sys_c, 'GJC') % present only for G,J,C constellations
                            valid_fit_int = any(getParStr(8, 2)' - 32);
                            eph_ss(valid_fit_int, 29) = getParNum(8, 2); % fit_int
                        end
                        
                        % Other parameter to stor in eph
                        eph_ss(:, 30) = eph_ss(:, 1) + (sys_index - 1); % go_id
                        eph_ss(:, 31) = int8(sys_c);
                        
                        [week, toc] = time.getGpsWeek;
                        eph_ss(:, 21) = toc;
                        eph_ss(:, 32) = double(week)*7*86400 + eph_ss(:, 18);
                        eph_ss(:, 33) = time.getGpsTime();
                        
                        if ismember(sys_c, 'G') % present only for G constellation
                            iodc = getParNum(7,4); % IODC
                            
                            time_thr = 0;
                            iod_check = (abs(eph_ss(:, 22) - iodc) > time_thr);
                            sat_ko = unique(eph_ss(iod_check, 1));
                            log = Core.getLogger;
                            %cm = log.getColorMode();
                            %log.setColorMode(0);
                            log.addWarning(sprintf('IODE - IODC of sat %sare different!\nPossible problematic broadcast orbits found for "%s"\nignoring those satellites', sprintf('G%02d ', sat_ko), File_Name_Processor.getFileName(file_nav)));
                            %log.setColorMode(cm);
                            eph_ss(iod_check, :) = []; % delete non valid ephemeris
                        end                                                
                    end
                    % Append SS ephemeris
                    eph = [eph eph_ss'];
                end
            end
        end
        
        % ---------------------------------------------------------------------------
        % Old goGPS functions , integrated with minor modifications as static methods
        %----------------------------------------------------------------------------
                
        function [Eph, iono, flag_return] = loadRinexNav(filename, cc, flag_SP3, iono_model, time, wait_dlg)
            
            % SYNTAX:
            %   [Eph, iono, flag_return] = loadRinexNav(filename, constellations, flag_SP3, iono_model, time, wait_dlg);
            %
            % INPUT:
            %   filename = RINEX navigation file
            %   cc = Constellation_Collector object, contains the satus of the satellite systems in use
            %   flag_SP3 = boolean flag to indicate SP3 availability
            %   wait_dlg = optional handler to waitbar figure (optional)
            %
            % OUTPUT:
            %   Eph = matrix containing 33 navigation parameters for each satellite
            %   iono = vector containing ionosphere parameters
            %   flag_return = notify the parent function that it should return
            %                 (downloaded navigation file still compressed).
            %
            % DESCRIPTION:
            %   Parses RINEX navigation files.
            
            % Check the input arguments
            if (nargin < 6)
                wait_dlg_PresenceFlag = false;
            else
                wait_dlg_PresenceFlag = true;
            end
            
            if (iscell(filename))
                filename = filename{1};
            end
            
            flag_return = 0;
            log = Logger.getInstance();
            state = Core.getCurrentSettings();
            
            %number of satellite slots for enabled constellations
            nSatTot = cc.getNumSat();
            
            %read navigation files
            if (~flag_SP3)
                parse_file(0);
            else
                Eph = zeros(33,nSatTot);
                iono = zeros(8,1);
            end
            
            % Broadcast corrections in DD are currently causing problems (offset in UP) => not using them
            %if Klobuchar ionospheric delay correction is requested but parameters are not available in the navigation file, try to download them
            if ((iono_model == 2 && ~any(iono)) || (flag_SP3 && cc.getGLONASS().isActive()))
                [week, sow] = time2weektow(time(1));
                [date, DOY] = gps2date(week, sow);
                
                filename_brdm = ['brdm' num2str(DOY,'%03d') '0.' num2str(two_digit_year(date(1,1)),'%02d') 'p'];
                filename_brdc = ['brdc' num2str(DOY,'%03d') '0.' num2str(two_digit_year(date(1,1)),'%02d') 'n'];
                filename_CGIM = ['CGIM' num2str(DOY,'%03d') '0.' num2str(two_digit_year(date(1,1)),'%02d') 'N'];
                
                pos = find(filename == '/'); if(isempty(pos)), pos = find(filename == '\'); end
                nav_path = filename(1:pos(end));
                
                flag_GLO = flag_SP3 && cc.getGLONASS().isActive();
                
                file_avail = 0;
                if (exist([nav_path filename_brdm],'file') && flag_GLO)
                    filename = [nav_path filename_brdm];
                    file_avail = 1;
                elseif (exist([nav_path filename_CGIM],'file') && ~flag_GLO)
                    filename = [nav_path filename_CGIM];
                    file_avail = 1;
                elseif (exist([nav_path filename_brdc],'file') && ~flag_GLO)
                    filename = [nav_path filename_brdc];
                    file_avail = 1;
                else
                    if (flag_GLO)
                        filename = filename_brdm;
                    else
                        filename = filename_brdc;
                    end
                    [download_successful, compressed] = download_nav(filename, nav_path);
                    filename = [nav_path filename];
                    if (download_successful)
                        file_avail = 1;
                    end
                    if (compressed)
                        flag_return = 1;
                    end
                end
                
                if (file_avail)
                    if (flag_GLO)
                        only_iono = 0;
                    else
                        only_iono = 1;
                    end
                    parse_file(only_iono);
                end
            end
            
            function parse_file(only_iono)
                
                if (wait_dlg_PresenceFlag)
                    waitbar(0.5,wait_dlg,'Reading navigation files...')
                end
                
                Eph_G = []; iono_G = zeros(8,1);
                Eph_R = []; iono_R = zeros(8,1);
                Eph_E = []; iono_E = zeros(8,1);
                Eph_C = []; iono_C = zeros(8,1);
                Eph_J = []; iono_J = zeros(8,1);
                Eph_I = []; iono_I = zeros(8,1);
                
                if (strcmpi(filename(end),'p'))
                    flag_mixed = 1;
                else
                    flag_mixed = 0;
                end
                
                if (cc.getGPS().isActive() || flag_mixed || only_iono)
                    if (exist(filename,'file'))
                        %parse RINEX navigation file (GPS) NOTE: filename expected to
                        %end with 'n' or 'N' (GPS) or with 'p' or 'P' (mixed GNSS)
                        if(~only_iono), log.addMessage(sprintf('%s',['Reading RINEX file ' filename ': ... '])); end
                        % [Eph_G, iono_G] = RINEX_get_nav(filename, cc); % Old implementation slower but support RINEX 2
                        [Eph_G, iono_G] = Core_Sky.loadNavParameters(filename, cc);
                        if(~only_iono), log.addStatusOk(); end
                    else
                        log.addWarning('GPS navigation file not found. Disabling GPS positioning. \n');
                        cc.deactivateGPS();
                    end
                end
                
                if (cc.getGLONASS().isActive() && ~only_iono)
                    if (exist([filename(1:end-1) 'g'],'file'))
                        %parse RINEX navigation file (GLONASS)
                        if(~only_iono), log.addMessage(sprintf('%s',['Reading RINEX file ' filename(1:end-1) 'g: ... '])); end
                        [Eph_R, iono_R] = Core_Sky.loadNavParameters([filename(1:end-1) 'g'], cc);
                        if(~only_iono), log.addStatusOk(); end
                    elseif (~flag_mixed)
                        log.addWarning('GLONASS navigation file not found. Disabling GLONASS positioning. \n');
                        cc.deactivateGLONASS();
                    end
                end
                
                if (cc.getGalileo().isActive() && ~only_iono)
                    if (exist([filename(1:end-1) 'l'],'file'))
                        %parse RINEX navigation file (Galileo)
                        if(~only_iono), log.addMessage(sprintf('%s',['Reading RINEX file ' filename(1:end-1) 'l: ... '])); end
                        [Eph_E, iono_E] = Core_Sky.loadNavParameters([filename(1:end-1) 'l'], cc);
                        if(~only_iono), log.addStatusOk(); end
                    elseif (~flag_mixed)
                        log.addWarning('Galileo navigation file not found. Disabling Galileo positioning. \n');
                        cc.deactivateGalileo();
                    end
                end
                
                if (cc.getBeiDou().isActive() && ~only_iono)
                    if (exist([filename(1:end-1) 'c'],'file'))
                        %parse RINEX navigation file (BeiDou)
                        if(~only_iono), log.addMessage(sprintf('%s',['Reading RINEX file ' filename(1:end-1) 'c: ... '])); end
                        [Eph_C, iono_C] = Core_Sky.loadNavParameters([filename(1:end-1) 'c'], cc);
                        if(~only_iono), log.addStatusOk(); end
                    elseif (~flag_mixed)
                        log.addWarning('BeiDou navigation file not found. Disabling BeiDou positioning. \n');
                        cc.deactivateBeiDou();
                    end
                end
                
                if (cc.getQZSS().isActive() && ~only_iono)
                    if (exist([filename(1:end-1) 'q'],'file'))
                        %parse RINEX navigation file (QZSS)
                        if(~only_iono), log.addMessage(sprintf('%s',['Reading RINEX file ' filename(1:end-1) 'q: ... '])); end
                        [Eph_J, iono_J] = Core_Sky.loadNavParameters([filename(1:end-1) 'q'], cc);
                        if(~only_iono), log.addStatusOk(); end
                    elseif (~flag_mixed)
                        log.addWarning('QZSS navigation file not found. Disabling QZSS positioning. \n');
                        cc.deactivateQZSS();
                    end
                end
                
                if (cc.getIRNSS().isActive() && ~only_iono)
                    if (exist([filename(1:end-1) 'i'],'file'))
                        %parse RINEX navigation file (IRNSS)
                        if(~only_iono), log.addMessage(sprintf('%s',['Reading RINEX file ' filename(1:end-1) 'q: ... '])); end
                        [Eph_I, iono_I] = Core_Sky.loadNavParameters([filename(1:end-1) 'i'], cc);
                        if(~only_iono), log.addStatusOk(); end
                    elseif (~flag_mixed)
                        log.addWarning('IRNSS navigation file not found. Disabling QZSS positioning. \n');
                        cc.deactivateIRNSS();
                    end
                end
                
                if (~only_iono)
                    Eph = [Eph_G Eph_R Eph_E Eph_C Eph_J Eph_I];
                end
                
                if (any(iono_G))
                    iono = iono_G;
                elseif (any(iono_R))
                    iono = iono_R;
                elseif (any(iono_E))
                    iono = iono_E;
                elseif (any(iono_C))
                    iono = iono_C;
                elseif (any(iono_J))
                    iono = iono_J;
                elseif (any(iono_I))
                    iono = iono_I;
                else
                    iono = zeros(8,1);
                    if isempty(regexp(filename, '(?<=brdm).*', 'once')) % brdm are broadcast mgex with no iono parameters, iono will be imported from other files
                        log.addWarning(sprintf('Klobuchar ionosphere parameters not found in navigation file\n("%s")\n', filename));
                    end
                end
                
                if (wait_dlg_PresenceFlag)
                    waitbar(1,wait_dlg)
                end
            end
        end
        
        function [satp, satv] = satelliteOrbits(t, Eph, sat, sbas)
            
            % SYNTAX:
            %   [satp, satv] = satelliteOrbits(t, Eph, sat, sbas);
            %
            % INPUT:
            %   t = clock-corrected GPS time
            %   Eph  = ephemeris matrix
            %   sat  = satellite index
            %   sbas = SBAS corrections
            %
            % OUTPUT:
            %   satp = satellite position (X,Y,Z)
            %   satv = satellite velocity
            %
            % DESCRIPTION:
            %   Computation of the satellite position (X,Y,Z) and velocity by means
            %   of its ephemerides.
            
            % the following two line offer an elegant but slow implementation
            %cc = Constellation_Collector('GRECJI');
            %sys_str = cc.getSys(char(Eph(31)));            
            % the following switch is equivalent to the previous two lines but musch faster
            switch char(Eph(31))
                case 'G'
                    sys_str = GPS_SS();
                case 'R'
                    sys_str = GLONASS_SS();
                case 'E'
                    sys_str = Galileo_SS();
                case 'C'
                    sys_str = BeiDou_SS();
                case 'J'
                    sys_str = QZSS_SS();
                case 'I'
                    sys_str = IRNSS_SS();
                case 'S'
                    sys_str = SBAS_SS();
            end
            
            orbital_p = sys_str.ORBITAL_P;
            Omegae_dot = orbital_p.OMEGAE_DOT;
            
            
            
            %consider BeiDou time (BDT) for BeiDou satellites
            if (strcmp(char(Eph(31)),'C'))
                t = t - 14;
            end
            
            %GPS/Galileo/BeiDou/QZSS satellite coordinates computation
            if (~strcmp(char(Eph(31)),'R'))
                
                %get ephemerides
                roota     = Eph(4);
                ecc       = Eph(6);
                omega     = Eph(7);
                cuc       = Eph(8);
                cus       = Eph(9);
                crc       = Eph(10);
                crs       = Eph(11);
                i0        = Eph(12);
                IDOT      = Eph(13);
                cic       = Eph(14);
                cis       = Eph(15);
                Omega0    = Eph(16);
                Omega_dot = Eph(17);
                toe       = Eph(18);
                time_eph  = Eph(32);
                
                %SBAS satellite coordinate corrections
                if (~isempty(sbas))
                    dx_sbas = sbas.dx(sat);
                    dy_sbas = sbas.dy(sat);
                    dz_sbas = sbas.dz(sat);
                else
                    dx_sbas = 0;
                    dy_sbas = 0;
                    dz_sbas = 0;
                end
                
                %-------------------------------------------------------------------------------
                % ALGORITHM FOR THE COMPUTATION OF THE SATELLITE COORDINATES (IS-GPS-200E)
                %-------------------------------------------------------------------------------
                
                %eccentric anomaly
                [Ek, n] = ecc_anomaly(t, Eph);
                
                cr = 6.283185307179600;
                
                A = roota*roota;             %semi-major axis
                tk = check_t(t - time_eph);  %time from the ephemeris reference epoch
                
                fk = atan2(sqrt(1-ecc^2)*sin(Ek), cos(Ek) - ecc);    %true anomaly
                phik = fk + omega;                           %argument of latitude
                phik = rem(phik,cr);
                
                uk = phik                + cuc*cos(2*phik) + cus*sin(2*phik); %corrected argument of latitude
                rk = A*(1 - ecc*cos(Ek)) + crc*cos(2*phik) + crs*sin(2*phik); %corrected radial distance
                ik = i0 + IDOT*tk        + cic*cos(2*phik) + cis*sin(2*phik); %corrected inclination of the orbital plane
                
                %satellite positions in the orbital plane
                x1k = cos(uk)*rk;
                y1k = sin(uk)*rk;
                
                %if GPS/Galileo/QZSS or MEO/IGSO BeiDou satellite
                if (~strcmp(char(Eph(31)),'C') || (strcmp(char(Eph(31)),'C') && Eph(1) > 5))
                    
                    %corrected longitude of the ascending node
                    Omegak = Omega0 + (Omega_dot - Omegae_dot)*tk - Omegae_dot*toe;
                    Omegak = rem(Omegak + cr, cr);
                    
                    %satellite Earth-fixed coordinates (X,Y,Z)
                    xk = x1k*cos(Omegak) - y1k*cos(ik)*sin(Omegak);
                    yk = x1k*sin(Omegak) + y1k*cos(ik)*cos(Omegak);
                    zk = y1k*sin(ik);
                    
                    %apply SBAS corrections (if available)
                    satp = zeros(3,1);
                    satp(1,1) = xk + dx_sbas;
                    satp(2,1) = yk + dy_sbas;
                    satp(3,1) = zk + dz_sbas;
                    
                else %if GEO BeiDou satellite (ranging code number <= 5)
                    
                    %corrected longitude of the ascending node
                    Omegak = Omega0 + Omega_dot*tk - Omegae_dot*toe;
                    Omegak = rem(Omegak + cr, cr);
                    
                    %satellite coordinates (X,Y,Z) in inertial system
                    xgk = x1k*cos(Omegak) - y1k*cos(ik)*sin(Omegak);
                    ygk = x1k*sin(Omegak) + y1k*cos(ik)*cos(Omegak);
                    zgk = y1k*sin(ik);
                    
                    %store inertial coordinates in a vector
                    Xgk = [xgk; ygk; zgk];
                    
                    %rotation matrices from inertial system to CGCS2000
                    Rx = [1        0          0;
                        0 +cosd(-5) +sind(-5);
                        0 -sind(-5) +cosd(-5)];
                    
                    oedt = Omegae_dot*tk;
                    
                    Rz = [+cos(oedt) +sin(oedt) 0;
                        -sin(oedt) +cos(oedt) 0;
                        0           0         1];
                    
                    %apply the rotations
                    Xk = Rz*Rx*Xgk;
                    
                    xk = Xk(1);
                    yk = Xk(2);
                    zk = Xk(3);
                    
                    %store CGCS2000 coordinates
                    satp = zeros(3,1);
                    satp(1,1) = xk;
                    satp(2,1) = yk;
                    satp(3,1) = zk;
                end
                
                %-------------------------------------------------------------------------------
                % ALGORITHM FOR THE COMPUTATION OF THE SATELLITE VELOCITY (as in Remondi,
                % GPS Solutions (2004) 8:181-183 )
                %-------------------------------------------------------------------------------
                if (nargout > 1)
                    Mk_dot = n;
                    Ek_dot = Mk_dot/(1-ecc*cos(Ek));
                    fk_dot = sin(Ek)*Ek_dot*(1+ecc*cos(fk)) / ((1-cos(Ek)*ecc)*sin(fk));
                    phik_dot = fk_dot;
                    uk_dot = phik_dot + 2*(cus*cos(2*phik)-cuc*sin(2*phik))*phik_dot;
                    rk_dot = A*ecc*sin(Ek)*Ek_dot + 2*(crs*cos(2*phik)-crc*sin(2*phik))*phik_dot;
                    ik_dot = IDOT + 2*(cis*cos(2*phik)-cic*sin(2*phik))*phik_dot;
                    Omegak_dot = Omega_dot - Omegae_dot;
                    x1k_dot = rk_dot*cos(uk) - y1k*uk_dot;
                    y1k_dot = rk_dot*sin(uk) + x1k*uk_dot;
                    xk_dot = x1k_dot*cos(Omegak) - y1k_dot*cos(ik)*sin(Omegak) + y1k*sin(ik)*sin(Omegak)*ik_dot - yk*Omegak_dot;
                    yk_dot = x1k_dot*sin(Omegak) + y1k_dot*cos(ik)*cos(Omegak) - y1k*sin(ik)*ik_dot*cos(Omegak) + xk*Omegak_dot;
                    zk_dot = y1k_dot*sin(ik) + y1k*cos(ik)*ik_dot;
                    
                    satv = zeros(3,1);
                    satv(1,1) = xk_dot;
                    satv(2,1) = yk_dot;
                    satv(3,1) = zk_dot;
                end
                
            else %GLONASS satellite coordinates computation (GLONASS-ICD 5.1)
                
                time_eph = Eph(32); %ephemeris reference time
                
                X   = Eph(5);  %satellite X coordinate at ephemeris reference time
                Y   = Eph(6);  %satellite Y coordinate at ephemeris reference time
                Z   = Eph(7);  %satellite Z coordinate at ephemeris reference time
                
                Xv  = Eph(8);  %satellite velocity along X at ephemeris reference time
                Yv  = Eph(9);  %satellite velocity along Y at ephemeris reference time
                Zv  = Eph(10); %satellite velocity along Z at ephemeris reference time
                
                Xa  = Eph(11); %acceleration due to lunar-solar gravitational perturbation along X at ephemeris reference time
                Ya  = Eph(12); %acceleration due to lunar-solar gravitational perturbation along Y at ephemeris reference time
                Za  = Eph(13); %acceleration due to lunar-solar gravitational perturbation along Z at ephemeris reference time
                %NOTE:  Xa,Ya,Za are considered constant within the integration interval (i.e. toe ?}15 minutes)
                
                %integration step
                int_step = 60; %[s]
                
                %time from the ephemeris reference epoch
                tk = check_t(t - time_eph);
                
                %number of iterations on "full" steps
                n = floor(abs(tk/int_step));
                
                %array containing integration steps (same sign as tk)
                ii = ones(n,1)*int_step*(tk/abs(tk));
                
                %check residual iteration step (i.e. remaining fraction of int_step)
                int_step_res = rem(tk,int_step);
                
                %adjust the total number of iterations and the array of iteration steps
                if (int_step_res ~= 0)
                    n = n + 1;
                    ii = [ii; int_step_res];
                end
                
                %numerical integration steps (i.e. re-calculation of satellite positions from toe to tk)
                pos = [X Y Z];
                vel = [Xv Yv Zv];
                acc = [Xa Ya Za];
                
                for s = 1 : n
                    
                    %Runge-Kutta numerical integration algorithm
                    %
                    %step 1
                    pos1 = pos;
                    vel1 = vel;
                    [pos1_dot, vel1_dot] = satellite_motion_diff_eq(pos1, vel1, acc, orbital_p.ELL.A, orbital_p.GM, sys_str.J2, orbital_p.OMEGAE_DOT);
                    %
                    %step 2
                    pos2 = pos + pos1_dot*ii(s)/2;
                    vel2 = vel + vel1_dot*ii(s)/2;
                    [pos2_dot, vel2_dot] = satellite_motion_diff_eq(pos2, vel2, acc, orbital_p.ELL.A, orbital_p.GM, sys_str.J2, orbital_p.OMEGAE_DOT);
                    %
                    %step 3
                    pos3 = pos + pos2_dot*ii(s)/2;
                    vel3 = vel + vel2_dot*ii(s)/2;
                    [pos3_dot, vel3_dot] = satellite_motion_diff_eq(pos3, vel3, acc, orbital_p.ELL.A, orbital_p.GM, sys_str.J2, orbital_p.OMEGAE_DOT);
                    %
                    %step 4
                    pos4 = pos + pos3_dot*ii(s);
                    vel4 = vel + vel3_dot*ii(s);
                    [pos4_dot, vel4_dot] = satellite_motion_diff_eq(pos4, vel4, acc, orbital_p.ELL.A, orbital_p.GM, sys_str.J2, orbital_p.OMEGAE_DOT);
                    %
                    %final position and velocity
                    pos = pos + (pos1_dot + 2*pos2_dot + 2*pos3_dot + pos4_dot)*ii(s)/6;
                    vel = vel + (vel1_dot + 2*vel2_dot + 2*vel3_dot + vel4_dot)*ii(s)/6;
                end
                
                %transformation from PZ-90.02 to WGS-84 (G1150)
                satp = zeros(3,1);
                satp(1,1) = pos(1) - 0.36;
                satp(2,1) = pos(2) + 0.08;
                satp(3,1) = pos(3) + 0.18;
                
                %satellite velocity
                satv = zeros(3,1);
                satv(1,1) = vel(1);
                satv(2,1) = vel(2);
                satv(3,1) = vel(3);
            end
            
        end
    end
end
