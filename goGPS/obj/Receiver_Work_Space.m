%   CLASS Receiver_Work_Space
% =========================================================================
%
%
%   Class to store receiver working paramters
%
% EXAMPLE
%   trg = Receiver_Work_Space();
%
% FOR A LIST OF CONSTANTs and METHODS use doc Receiver

%--------------------------------------------------------------------------
%               ___ ___ ___
%     __ _ ___ / __| _ | __|
%    / _` / _ \ (_ |  _|__ \
%    \__, \___/\___|_| |___/
%    |___/                    v 1.0 beta 2
%
%--------------------------------------------------------------------------
%  Copyright (C) 2009-2018 Mirko Reguzzoni, Eugenio Realini
%  Written by:       Gatti Andrea, Giulio Tagliaferro ...
%  Contributors:
%  A list of all the historical goGPS contributors is in CREDITS.nfo
%--------------------------------------------------------------------------
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%--------------------------------------------------------------------------
classdef Receiver_Work_Space < Receiver_Commons
    %% CONSTANTS
    properties (Constant)
        S02_IP_THR = 1e3;
    end
    
    % ==================================================================================================================================================
    %% PROPERTIES RECEIVER
    
    properties (SetAccess = public, GetAccess = public)
        
        file            % list of rinex file loaded
        rinex_file_name % list of RINEX file name
        rin_type       % rinex version format
        loaded_session = 0;  % id of the loaded session data
        
        rinex_ss       % flag containing the satellite system of the rinex file, G: GPS, R: GLONASS, E: Galileo, J: QZSS, C: BDS, I: IRNSS, S: SBAS payload, M: Mixed
        
        
        n_sat = 0;     % number of satellites
        n_freq = 0;    % number of stored frequencies
        n_spe = [];    % number of observations per epoch
        
        rec_settings;  % receiver settings
        
        
    end
    % ==================================================================================================================================================
    % ==================================================================================================================================================
    %% PROPERTIES OBSERVATIONS
    % ==================================================================================================================================================
    
    properties (SetAccess = public, GetAccess = public)
        active_ids     % rows of active satellites
        wl             % wave-length of each row of row_id
        f_id           % frequency number e.g. L1 -> 1,  L2 ->2, E1 -> 1, E5b -> 3 ...
        prn            % pseudo-range number of the satellite
        go_id          % internal id for a certain satellite
        system         % char id of the satellite system corresponding to the row_id
        
        obs_code       % obs code for each line of the data matrix obs
        obs            % huge observation matrix with all the observables for all the systems / frequencies / ecc ...
        synt_ph;       % syntetic phases
        
        dop_kin        % dop matrix inberse of the normal builded for a sigle epoch [ x y z dt tropo]
        dop_tdt        % dop matrix inberse of the normal builded for a sigle epoch [dt tropo]
        
        
        % CORRECTIONS ------------------------------
        
        rin_obs_code   % list of types per constellation
        ph_shift       % phase shift as read from RINEX files
        
        ocean_load_disp = [];        % ocean loading displacemnet for the station , -1 if not found
        clock_corrected_obs = false; % if the obs have been corrected with dt * v_light this flag should be true
        pcv = []                     % phase center corrections for the receiver
        
        pp_status = false;      % flag is pre-proccesed / not pre-processed
        iono_status           = 0; % flag to indicate if measurements ahave been corrected by an external ionpheric model
        group_delay_status    = 0; % flag to indicate if code measurement have been corrected using group delays                          (0: not corrected , 1: corrected)
        dts_delay_status      = 0; % flag to indicate if code and phase measurement have been corrected for the clock of the satellite    (0: not corrected , 1: corrected)
        sh_delay_status       = 0; % flag to indicate if code and phase measurement have been corrected for shapiro delay                 (0: not corrected , 1: corrected)
        pcv_delay_status      = 0; % flag to indicate if code and phase measurement have been corrected for pcv variations                (0: not corrected , 1: corrected)
        ol_delay_status       = 0; % flag to indicate if code and phase measurement have been corrected for ocean loading                 (0: not corrected , 1: corrected)
        pt_delay_status       = 0; % flag to indicate if code and phase measurement have been corrected for pole tides                    (0: not corrected , 1: corrected)
        pw_delay_status       = 0; % flag to indicate if code and phase measurement have been corrected for phase wind up                 (0: not corrected , 1: corrected)
        et_delay_status       = 0; % flag to indicate if code and phase measurement have been corrected for solid earth tide              (0: not corrected , 1: corrected)
        hoi_delay_status      = 0; % flag to indicate if code and phase measurement have been corrected for high order ionospheric effect (0: not corrected , 1: corrected)
        atm_load_delay_status = 0; % flag to indicate if code and phase measurement have been corrected for atmospheric loading           (0: not corrected , 1: corrected)
        ph_shift_status       = 1; % flag to indicate if phase shift is applied
        
        % FLAGS ------------------------------
        
        ph_idx             % idx of outlier and cycle slip in obs, 
                           % corresponding index in .obs of the columns of outlier and cs in .sat
        
        if_amb;            % temporary varibale to test PPP ambiguity fixing
        
        flag_currupted = false;
    end
    % ==================================================================================================================================================
    %% PROPERTIES POSITION
    % ==================================================================================================================================================
    
    properties (SetAccess = public, GetAccess = public)
        xyz_approx     % approximate position of the receiver (XYZ geocentric)
    end
    % ==================================================================================================================================================
    %% PROPERTIES CELESTIAL INFORMATIONS
    % ==================================================================================================================================================
    
    properties (SetAccess = public, GetAccess = public)
        sat = struct( ...
            'avail_index',      [], ...    % boolean [n_epoch x n_sat] availability of satellites
            'outliers',         [], ...    % outlier    processing to be saved in result
            'cycle_slip',          [], ...    % cycle slip processing to be saved in result
            'outliers_ph_by_ph',   [], ...    % logical index of outliers
            'cicle_slip_ph_by_ph',[], ...    % logical index of cycle slips
            'err_tropo',        [], ...    % double  [n_epoch x n_sat] tropo error
            'slant_td',         [], ...    % double  [n_epoch x n_sat] slant total delay
            'err_iono',         [], ...    % double  [n_epoch x n_sat] iono error
            'solid_earth_corr', [], ...    % double  [n_epoch x n_sat] solid earth corrections
            'dtS',              [], ...    % double  [n_epoch x n_sat] staellite clok error at trasmission time
            'rel_clk_corr',     [], ...    % double  [n_epoch x n_sat] relativistic correction at trasmission time
            'tot',              [], ...    % double  [n_epoch x n_sat] time of travel
            'az',               [], ...    % double  [n_epoch x n_sat] azimuth
            'el',               [], ...    % double  [n_epoch x n_sat] elevation
            'cs',               [], ...    % Core_Sky
            'XS_tx',            [], ...    % compute Satellite postion a t transmission time
            'crx',              [], ...    % bad epochs based on crx file
            'res',              [], ...    % residual per staellite
            'amb_idx',          [], ...    % idex of the ambiguity for each epoch of the pahse measurement
            'is_amb_fixed',     [], ...    % for each index of amb_idx tell is the ambiguity is fixed
            'amb_val',          [], ...    % Value of the fixed ambiguity
            'amb_mat',          [], ...    % Full ambiguity matrix
            'amb',              [], ...
            'last_repair',      [] ...     % last integer ambiguity repair per go_id size: [#n_observables x 1],
            ...                            % for easyness of use it is larger than necessary it could be [#n_phases x 1]
            ...                            % it could be changed in the future
            )
    end
    % ==================================================================================================================================================
    %% PROPERTIES TIME
    % ==================================================================================================================================================
    
    properties (SetAccess = public, GetAccess = public)
        id_sync        % id of the epochs used for computing the solution
        rate           % observations rate;
        dt_ph          % clock error for the phases generated by the de-sync process
        dt_pr          % clock error for the pseudo-ranges generated by the de-sync process
        
        out_start_time % time bound of output start
        out_stop_time  % time bound of output end
    end
    
    % ==================================================================================================================================================
    %% PROPERTIES TROPO
    % ==================================================================================================================================================
    
    properties (SetAccess = public, GetAccess = public)
        meteo_data % meteo data object
    end
    % ==================================================================================================================================================
    %% METHODS INIT - CLEAN - RESET - REM -IMPORT
    % ==================================================================================================================================================
    
    methods
        function this = Receiver_Work_Space(cc, parent)
            % SYNTAX  this = Receiver(<cc>)
            
            this.parent = parent;
            if nargin >= 1 && ~isempty(cc)
                this.cc = cc;
            else
                this.cc = this.state.cc;
            end
            this.rec_settings = Receiver_Settings();
            this.reset();
        end
        
        function reset(this)
            this.initHandles();
            
            this.reset@Receiver_Commons();
            this.resetObs();
            this.initR2S(); % restore handle to core_sky singleton
            this.id_sync = [];
            
            this.n_sat = [];
            
            this.pp_status = false;
            this.group_delay_status = 0; % flag to indicate if code measurement have been corrected using group delays                          (0: not corrected , 1: corrected)
            this.dts_delay_status   = 0; % flag to indicate if code and phase measurement have been corrected for the clock of the satellite    (0: not corrected , 1: corrected)
            this.sh_delay_status    = 0; % flag to indicate if code and phase measurement have been corrected for shapiro delay                 (0: not corrected , 1: corrected)
            this.pcv_delay_status   = 0; % flag to indicate if code and phase measurement have been corrected for pcv variations                (0: not corrected , 1: corrected)
            this.ol_delay_status    = 0; % flag to indicate if code and phase measurement have been corrected for ocean loading                 (0: not corrected , 1: corrected)
            this.pt_delay_status    = 0; % flag to indicate if code and phase measurement have been corrected for pole tides                    (0: not corrected , 1: corrected)
            this.pw_delay_status    = 0; % flag to indicate if code and phase measurement have been corrected for phase wind up                 (0: not corrected , 1: corrected)
            this.et_delay_status    = 0; % flag to indicate if code and phase measurement have been corrected for solid earth tide              (0: not corrected , 1: corrected)
            this.hoi_delay_status   = 0; % flag to indicate if code and phase measurement have been corrected for high order ionospheric effect          (0: not corrected , 1: corrected)
            
            this.sat.avail_index       = [];
            this.sat.outliers_ph_by_ph    = [];
            this.sat.cicle_slip_ph_by_ph = [];
            this.sat.err_tropo         = [];
            this.sat.err_iono          = [];
            this.sat.solid_earth_corr  = [];
            this.sat.dtS               = [];
            this.sat.rel_clk_corr      = [];
            this.sat.tot               = [];
            this.sat.az                = [];
            this.sat.el                = [];
            this.sat.XS_tx             = [];
            this.sat.crx               = [];
            this.sat.res               = [];
            this.sat.slant_td          = [];
            this.sat.cycle_slip           = [];
            this.sat.outliers          = [];
            this.sat.amb_mat           = [];
            this.sat.amb_idx           = [];
            this.sat.amb               = [];
            this.add_coo               = [];
        end
        
        function resetObs(this)
            % Reset the content of the receiver obj
            % SYNTAX
            %   this.initObs;
            
            this.file = [];             % file rinex object
            this.rin_type = 0;          % rinex version format
            
            this.parent.ant          = 0;       % antenna number
            this.parent.ant_type     = '';      % antenna type
            this.parent.ant_delta_h  = 0;       % antenna height from the ground [m]
            this.parent.ant_delta_en = [0 0];   % antenna east/north offset from the ground [m]
            
            this.rin_obs_code = '';       % list of types per constellation
            this.ph_shift     = [];
            
            this.xyz          = [0 0 0];  % approximate position of the receiver (XYZ geocentric)
            
            this.parent.static       = true;     % the receivers are considered static unless specified
            
            this.n_sat = 0;               % number of satellites
            this.n_freq = 0;              % number of stored frequencies
            this.n_spe = [];              % number of sat per epoch
            
            this.rate = 0;                % observations rate;
            
            this.desync = 0;              % clock offset of the receiver
            this.dt_ph = 0;               % clock offset of the receiver
            this.dt_pr = 0;               % clock offset of the receiver
            this.dt_ip = 0;               % clock offset of the receiver
            this.dt = 0;                  % clock offset of the receiver
            this.flag_rid = 0;            % clock offset of the receiver
            
            this.active_ids = [];         % rows of active satellites
            this.wl         = [];         % wave-length of each row of row_id
            this.f_id       = [];         % frequency number e.g. L1 -> 1,  L2 ->2, E1 -> 1, E5b -> 3 ...
            this.prn        = [];         % pseudo-range number of the satellite
            this.go_id      = [];         % internal id for a certain satellite
            this.system     = '';         % char id of the satellite system corresponding to the row_id
            
            this.obs_code   = [];         % obs code for each line of the data matrix obs
            this.obs        = [];         % huge observation matrix with all the observables for all the systems / frequencies / ecc ...
            
            this.ph_idx = [];
            this.if_amb = [];
            this.synt_ph = [];
            
            this.clock_corrected_obs = false; % if the obs have been corrected with dt * v_light this flag should be true
        end
        
        function resetWorkSpace(this,append)
            this.initHandles();
            if nargin < 2
                append = false;
            end
            if ~append
                this.file = File_Rinex();
                this.rinex_file_name = '';
                this.rin_type = 0;
                this.time = GPS_Time();
                this.rin_obs_code = '';       % list of types per constellation
                this.ph_shift     = [];
                
                this.active_ids = [];         % rows of active satellites
                this.wl         = [];         % wave-length of each row of row_id
                this.f_id       = [];         % frequency number e.g. L1 -> 1,  L2 ->2, E1 -> 1, E5b -> 3 ...
                this.prn        = [];         % pseudo-range number of the satellite
                this.go_id      = [];         % internal id for a certain satellite
                this.system     = '';         % char id of the satellite system corresponding to the row_id
                
                this.obs_code   = [];         % obs code for each line of the data matrix obs
                this.obs        = [];         % huge observation matrix with all the observables for all the systems / frequencies / ecc ...
                this.n_spe = [];              % number of sat per epoch
                this.xyz          = [];  % approximate position of the receiver (XYZ geocentric)
                
                this.iono_status = false;
                this.group_delay_status = false;
                this.dts_delay_status = false;
                this.sh_delay_status = false;
                this.pcv_delay_status = false;
                this.ol_delay_status = false;
                this.pt_delay_status = false;
                this.pw_delay_status = false;
                this.et_delay_status = false;
                this.hoi_delay_status = false;
                this.atm_load_delay_status = false;
            end
            
            this.pp_status = false;
            
            this.id_sync = [];
            this.n_sat = [];
            this.n_sat_ep = [];
            
            this.enu = [];
            this.lat = [];
            this.lon = [];
            this.h_ellips = [];
            this.h_ortho = [];
            
            this.n_sat = 0;               % number of satellites
            this.n_freq = 0;              % number of stored frequencies
            
            
            this.rate = 0;                % observations rate;
            
            this.desync = 0;              % clock offset of the receiver
            this.dt_ph = 0;               % clock offset of the receiver
            this.dt_pr = 0;               % clock offset of the receiver
            this.dt_ip = 0;               % clock offset of the receiver
            this.dt = 0;                  % clock offset of the receiver
            this.flag_rid = 0;            % clock offset of the receiver
            
            this.ph_idx = [];
            this.if_amb = [];
            this.synt_ph = [];
            
            this.clock_corrected_obs = false; % if the obs have been corrected with dt * v_light this flag should be true
            
            this.quality_info = struct('s0', [], 's0_ip', [], 'n_epochs', [], 'n_obs', [], 'n_out', [], 'n_sat', [], 'n_sat_max', [], 'fixing_ratio', [], 'C_pos_pos', []);
            
            this.a_fix = [];
            this.s_rate = [];
            
            this.apr_zhd  = [];
            this.zwd  = [];
            this.apr_zwd  = [];
            this.ztd  = [];
            this.pwv  = [];
            
            this.tgn = [];
            this.tge = [];
            
            this.sat.avail_index       = [];
            this.sat.outliers_ph_by_ph    = [];
            this.sat.cicle_slip_ph_by_ph = [];
            this.sat.err_tropo         = [];
            this.sat.err_iono          = [];
            this.sat.solid_earth_corr  = [];
            this.sat.dtS               = [];
            this.sat.rel_clk_corr      = [];
            this.sat.tot               = [];
            this.sat.az                = [];
            this.sat.el                = [];
            this.sat.XS_tx             = [];
            this.sat.crx               = [];
            this.sat.res               = [];
            this.sat.slant_td          = [];
            this.sat.cycle_slip           = [];
            this.sat.outliers          = [];
            this.sat.amb_mat           = [];
            this.sat.amb_idx           = [];
            this.sat.amb               = [];
            
            this.add_coo               = [];
        end
        
        function load(this, t_start, t_stop, rate)
            % Load the rinex file linked to this receiver
            %
            % SYNTAX
            %   this.load(<t_start>, <t_stop>, <rate>)
            %   this.load(<rate>);
            
            if ~isempty(this.rinex_file_name)
                if nargin > 3
                    this.importRinex(this.rinex_file_name, t_start, t_stop, rate);
                elseif nargin == 2 % the only parameter is rate
                    rate = t_start;
                    this.importRinex(this.rinex_file_name, [], [], rate);
                else
                    this.importRinex(this.rinex_file_name);
                end
                this.importAntModel();
            end
            rf = Core.getReferenceFrame(true);
            coo = rf.getCoo(this.parent.getMarkerName4Ch, this.getCentralTime);
            if ~isempty(coo)
                this.xyz = coo;
            end
        end
        
        function prepareAppending(this, time_start, time_stop)
            % remove epochs and remoce corrections
            %
            % SYNTAX:
            %   this.prepareAppending( time_start, time_stop)
            
            % remove unwanted epochs
            id_to_remove = this.time < time_start | this.time > time_stop;
            this.remEpochs(id_to_remove);
            this.remAllCorrections();
            if ~this.time.isempty
                this.restoreDtError();
            end
            this.resetWorkSpace(true);
            % removing "fake" observations syntetized by the SEID approach
            id_obs = this.obs_code(:,3) == 'F';
            this.remObs(id_obs);
        end
        
        function importRinexFileList(this, rin_list, time_start, time_stop, rate)
            % imprt a list of rinex files
            %
            % SYNTAX:
            %   this.importRinexFileList(rin_list, time_start, time_stop, rate)
            % check which files have to be added
            if time_start.isempty
                time_start = GPS_Time(0);
            else
                if ~this.time.isempty
                    time_start = this.time.last;
                end
            end
            rin_list.keepFiles(time_start, time_stop);
            n_files = length(rin_list.file_name_list);
            for i = 1 : n_files
                tmp = time_stop.getCopy;
                if tmp > rin_list.last_epoch.getEpoch(i)
                    tmp = rin_list.last_epoch.getEpoch(i).getCopy;
                end
                this.appendRinex(rin_list.getFileName(i),time_start, time_stop, rate)
            end
            if ~this.isEmpty
                this.setActiveSys(this.getAvailableSys);
            end
        end
        
        function appendRinex(this, rinex_file_name, time_start, time_stop, rate)
            % append a rinex files
            %
            % SYNTAX:
            %  this.appendRinex(rinex_file_name,time_start, time_stop)
            rec = Receiver_Work_Space(this.cc, this.parent);
            rec.rinex_file_name = rinex_file_name;
            rec.load(time_start, time_stop, rate);
            
            if this.state.flag_amb_pass && ~isempty(this.parent.old_work) && ~this.parent.old_work.isEmpty
                [ph, wl, id_ph] = rec.getPhases();
                id_ph = find(id_ph);
                for i = 1 : length(id_ph)
                    amb_off = this.parent.old_work.getLastRepair(rec.go_id(id_ph(i)), rec.obs_code(id_ph(i),2:3));
                    if ~isempty(amb_off) && amb_off ~= 0
                        ph(:,i) = ph(:,i) - amb_off * wl(i);
                    end
                end
                rec.setPhases(ph, wl, id_ph);
            end
            % merge the two rinex
            this.injestReceiver(rec);
        end
        
        function injestReceiver(this, rec)
            % injest one receiver_work_state object
            % NOTE: this methods does not manage the case when the two receivers have overlapping times
            %
            % SYNTAX
            %  this.injestReceiver(rec);
            
            % Remove duplicate epochs, epochs in the receiver that are read again
            [~, id_ko] = intersect(round(this.time.getMatlabTime * this.time.getRate/5/86400), round(rec.time.getMatlabTime * this.time.getRate/5/86400));
            rec.remEpochs(id_ko);
            
            n_obs = size(rec.obs,1);
            old_length = this.time.length;
            
            if ~isempty(this.obs)
                %expand the times and the obs
                this.time.append(rec.time);
                new_length = this.time.length();
                this.obs = [this.obs zeros(size(this.obs,1),rec.time.length)];
                this.n_spe = [this.n_spe  rec.n_spe];
                for i = 1:n_obs
                    sat_idx = this.go_id == rec.go_id(i);
                    obs_idx = strLineMatch(this.obs_code, rec.obs_code(i,:));
                    obs_idx = obs_idx & sat_idx;
                    if sum(obs_idx) > 0 % if the observation os already present
                        this.obs(obs_idx,(old_length+1):end) = rec.obs(i,:);
                    else
                        % expand all the fields
                        this.obs = [this.obs; zeros(1,new_length)];
                        this.obs(end,(old_length+1):end) = rec.obs(i,:);
                        this.active_ids = [this.active_ids; true];
                        this.wl       = [this.wl      ; rec.wl(i)];
                        this.f_id     = [this.f_id    ; rec.f_id(i)];
                        this.prn      = [this.prn     ; rec.prn(i)];
                        this.go_id    = [this.go_id   ; rec.go_id(i)];
                        this.system      = [this.system      rec.system(i)];
                        this.obs_code = [this.obs_code; rec.obs_code(i,:)];
                    end
                end
            else
                this.time = rec.time.getCopy();
                this.obs = rec.obs;
                this.active_ids = rec.active_ids;
                this.wl       = rec.wl;
                this.f_id     = rec.f_id;
                this.prn      = rec.prn;
                this.go_id    = rec.go_id;
                this.system   = rec.system;
                this.obs_code = rec.obs_code;
                this.n_spe      = rec.n_spe;
                this.xyz = rec.xyz;
                this.xyz_approx = rec.xyz_approx;
                this.ph_shift = rec.ph_shift;
                this.pcv = rec.pcv;
                this.rate = rec.rate;
                this.file            = rec.file;
                this.rinex_file_name = rec.rinex_file_name;
                this.rin_type        = rec.rin_type;
                this.rinex_ss        = rec.rinex_ss;
                this.n_sat           = rec.n_sat;
                this.n_freq          = rec.n_freq;
                this.rin_obs_code    = rec.rin_obs_code;
            end
        end
        
        function initTropo(this)
            % initialize tropo variables
            n_epoch = this.time.length;
            this.ztd = nan(n_epoch, 1);
            this.apr_zhd = nan(n_epoch, 1);
            this.zwd = nan(n_epoch, 1);
            this.apr_zwd = nan(n_epoch, 1);
            this.pwv = nan(n_epoch, 1);
            this.tge = nan(n_epoch, 1);
            this.tgn = nan(n_epoch, 1);
        end
        
        function initR2S(this)
            % initialize satellite related parameters
            % SYNTAX this.initR2S();
            this.sat.cs           = Core.getCoreSky();
            % this.sat.avail_index  = false(this.length, this.cc.getMaxNumSat);
            % this.sat.XS_tx     = NaN(n_epoch, n_pr); % --> consider what to initialize
        end
        
        function subSample(this, id_sync)
            % keep epochs id_sync
            % SYNTAX   this.subSample(id_sync)
            if (nargin < 2)
                id_sync = this.id_sync;
            end
            if ~isempty(id_sync)
                this.obs(id_sync, :) = [];
            end
        end
        
        function remObs(this, id_obs)
            % remove observable with a certain id
            %
            % SYNTAX
            %   this.remObs(id_obs)
            if islogical(id_obs)
                id_obs = find(id_obs);
            end
            this.obs(intersect(1 : size(this.obs,1), id_obs),:) = [];
            this.obs_code(id_obs, :) = [];
            this.active_ids(intersect(1:size(this.active_ids,1), id_obs)) = [];
            this.wl(id_obs) = [];
            this.f_id(id_obs) = [];
            this.prn(id_obs) = [];
            
            this.system(id_obs) = [];
            
            go_out = this.go_id(intersect(1 : size(this.go_id, 1), id_obs));
            this.go_id(intersect(1 : size(this.go_id, 1), id_obs)) = [];
            go_out = setdiff(go_out, unique(this.go_id));
            
            id_out = [];
            for i = 1 : numel(id_obs)
                id_out = [id_out, find(this.ph_idx == id_obs(i))]; %#ok<AGROW>
            end
            if ~isempty(this.ph_idx)
                if isempty(this.obs_code)
                    this.ph_idx = [];
                else
                    this.ph_idx = find(this.obs_code(1,:) == 'L');
                end
            end
            
            % try to remove observables from other precomputed properties of the object
            if ~isempty(this.synt_ph)
                this.synt_ph(:,id_out) = [];
            end
            if ~isempty(this.sat.outliers_ph_by_ph)
                this.sat.outliers_ph_by_ph(:,id_out) = [];
            end
            if ~isempty(this.sat.cicle_slip_ph_by_ph)
                this.sat.cicle_slip_ph_by_ph(:,id_out) = [];
            end
            
            % try to remove observables from other precomputed properties of the object in sat
            
            if ~isempty(this.sat.avail_index)
                this.sat.avail_index(:, go_out) = false;
            end
            
            if ~isempty(this.sat.err_tropo)
                this.sat.err_tropo(:, go_out) = 0;
            end
            if ~isempty(this.sat.err_iono)
                this.sat.err_iono(:, go_out) = 0;
            end
            if ~isempty(this.sat.solid_earth_corr)
                this.sat.solid_earth_corr(:, go_out) = 0;
            end
            if ~isempty(this.sat.tot)
                this.sat.tot(:, go_out) = 0;
            end
            if ~isempty(this.sat.az)
                this.sat.az(:, go_out) = 0;
            end
            if ~isempty(this.sat.el)
                this.sat.el(:, go_out) = 0;
            end
            if ~isempty(this.sat.res)
                this.sat.res(:, go_out) = 0;
            end
            if ~isempty(this.sat.slant_td)
                this.sat.slant_td(:, go_out) = 0;
            end
            try
                if ~isempty(this.sat.amb)
                    this.sat.amb(:, go_out) = 0;
                end
                if ~isempty(this.sat.amb_mat)
                    this.sat.amb_mat(:, go_out) = 0;
                end
            catch
            end
        end
        
        function keepEpochs(this, good_epochs)
            % keep epochs with a certain id
            %
            % SYNTAX
            %   this.keepEpochs(good_epochs)
            bad_epochs = 1 : this.time.length;
            bad_epochs(good_epochs) = [];
            this.remEpochs(bad_epochs)
        end
        
        function keepBestTracking(this)
            % keep only the best available tracking per frequency
            %
            % SYNTAX:
            %   this.keepBestTracking()
            id_2_rm = []; % id to be removed
            obs_code = this.getAvailableObsCode();
            for s = 1 : this.getMaxSat()
                os_idx = this.go_id == s;
                freq = unique(this.obs_code(os_idx,2))';
                for f = freq
                    f_lid = this.obs_code(:,2) == f & os_idx;
                    f_id = find(f_lid);
                    
                    pr_id = this.obs_code(f_id,1) == 'C';
                    ph_id = this.obs_code(f_id,1) == 'L';
                    dp_id = this.obs_code(f_id,1) == 'D';
                    snr_id = this.obs_code(f_id,1) == 'S';
                    
                    % CODE ----------------------------------------------------------------------------------------------
                    if sum(pr_id) > 1
                        % I have more tracking for the current freq of the current sat
                        trks = this.obs_code(f_id(pr_id), 3);
                        trks = unique(trks);
                        trks_pos = zeros(size(trks)); % position in tracking preferences
                        sys_c = this.system(f_id(1));
                        ssystem = this.cc.getSys(sys_c);
                        for t = 1 : length(trks)
                            trk = trks(t);
                            trks_pos(t) = find(ssystem.CODE_RIN3_ATTRIB{ssystem.CODE_RIN3_2BAND == f} == trk);
                        end
                        best_trk =  min(trks_pos); % best tracking
                        best_trk_pr = trks(best_trk);
                    else
                        best_trk_pr = this.obs_code(f_id(pr_id), 3);
                    end
                    
                    % PHASE ---------------------------------------------------------------------------------------------
                    if sum(ph_id) > 1
                        % I have more tracking for the current freq of the current sat
                        trks = this.obs_code(f_id(ph_id), 3);
                        trks = unique(trks);
                        trks_pos = zeros(size(trks)); % position in tracking preferences
                        sys_c = this.system(f_id(1));
                        ssystem = this.cc.getSys(sys_c);
                        for t = 1 : length(trks)
                            trk = trks(t);
                            trks_pos(t) = find(ssystem.CODE_RIN3_ATTRIB{ssystem.CODE_RIN3_2BAND == f} == trk);
                        end
                        best_trk =  min(trks_pos); % best tracking
                        best_trk_ph = trks(best_trk);
                    else
                        best_trk_ph = this.obs_code(f_id(ph_id), 3);
                    end
                    
                    % If no trasking is not found no data is available
                    if isempty(best_trk_ph) 
                       best_trk_ph = '*';
                    end
                    if isempty(best_trk_pr) 
                       best_trk_pr = '*';
                    end
                    
                    % find obs to be removed ----------------------------------------------------------------------------
                    id_2_rm = [id_2_rm; find((this.obs_code(:,1) == 'C' & this.obs_code(:,3) ~= best_trk_pr & f_lid) ...
                        | (this.obs_code(:,1) == 'L' & this.obs_code(:,3) ~= best_trk_ph & f_lid) ...
                        | ((this.obs_code(:,1) == 'S' | this.obs_code(:,1) == 'D') & (this.obs_code(:, 3) ~= best_trk_pr & this.obs_code(:, 3) ~= best_trk_ph & this.obs_code(:, 3) ~= ' ') & f_lid))];
                end
            end
            % delete only bad tracking that are not SNR or Doppler with empty mode
            id_2_rm = setdiff(id_2_rm, find((this.obs_code(:,1) == 'S' | this.obs_code(:,1) == 'D') & this.obs_code(:, 3) == ' '));
            if ~isempty(id_2_rm)
                this.remObs(id_2_rm);
            end
        end
        
        function keep(this, rate, sys_list)
            % keep epochs at a certain rate for a certain constellation
            %
            % SYNTAX
            %   this.keep(rate, sys_list)
            if nargin > 1 && ~isempty(rate)
                [~, id_sync] = Receiver_Commons.getSyncTimeExpanded(this, rate);
                if ~isempty(id_sync)
                    this.keepEpochs(id_sync(~isnan(id_sync)));
                end
            end
            if nargin > 2 && ~isempty(sys_list)
                this.setActiveSys(sys_list);
                this.remSat(this.go_id(regexp(this.system, ['[^' sys_list ']'])));
            end
        end
        
        function remEpochs(this, bad_epochs)
            % remove epochs with a certain id
            %
            % SYNTAX
            %   this.remEpochs(bad_epochs)
            if islogical(bad_epochs)
                bad_epochs = find(bad_epochs);
            end
            if ~isempty(bad_epochs)
                
                if ~isempty(this.sat.cicle_slip_ph_by_ph)
                    cycle_slip = this.sat.cicle_slip_ph_by_ph;
                    
                    tmp = false(max(bad_epochs), 1); tmp(bad_epochs) = true;
                    lim = getOutliers(tmp);
                    
                    if lim(end) == size(cycle_slip, 1)
                        lim(end,:) = [];
                    end
                    lim(:,2) = min(lim(:,2) + 1, size(cycle_slip, 1));
                    for l = 1 : size(lim, 1)
                        cycle_slip(lim(l, 2), :) = any(cycle_slip(lim(l, 1) : lim(l, 2), :));
                    end
                    cycle_slip(bad_epochs,:) = [];
                    
                    this.sat.cicle_slip_ph_by_ph = cycle_slip;
                end
                n_ep = this.time.length;
                this.time.remEpoch(bad_epochs);
                
                if ~isempty(this.n_spe)
                    this.n_spe(bad_epochs) = [];
                end
                
                if ~isempty(this.synt_ph)
                    this.synt_ph(bad_epochs, :) = [];
                end
                if ~isempty(this.obs)
                    this.obs(:, bad_epochs) = [];
                end
                
                if ~isempty(this.sat.outliers_ph_by_ph)
                    this.sat.outliers_ph_by_ph(bad_epochs, :) = [];
                end
                
                if ~isempty(this.id_sync)
                    tmp = false(n_ep, 1);
                    tmp(this.id_sync) = true;
                    tmp(bad_epochs) = [];
                    this.id_sync = find(tmp);
                end
                
                if numel(this.desync) > 1
                    this.desync(bad_epochs) = [];
                end
                if numel(this.dt) > 1
                    this.dt(bad_epochs) = [];
                end
                if numel(this.dt_ph) > 1
                    this.dt_ph(bad_epochs) = [];
                end
                if numel(this.dt_pr) > 1
                    this.dt_pr(bad_epochs) = [];
                end
                if numel(this.dt_ip) > 1
                    this.dt_ip(bad_epochs) = [];
                end
                
                if ~isempty(this.apr_zhd)
                    this.apr_zhd(bad_epochs) = [];
                end
                if ~isempty(this.ztd)
                    this.ztd(bad_epochs) = [];
                end
                if ~isempty(this.zwd)
                    this.zwd(bad_epochs) = [];
                end
                if ~isempty(this.apr_zwd)
                    this.apr_zwd(bad_epochs) = [];
                end
                if ~isempty(this.pwv)
                    this.pwv(bad_epochs) = [];
                end
                if ~isempty(this.tgn)
                    this.tgn(bad_epochs) = [];
                end
                if ~isempty(this.tge)
                    this.tge(bad_epochs) = [];
                end
                
                if ~isempty(this.sat.avail_index)
                    this.sat.avail_index(bad_epochs, :) = [];
                end
                if ~isempty(this.sat.err_tropo)
                    this.sat.err_tropo(bad_epochs, :) = [];
                end
                if ~isempty(this.sat.err_iono)
                    this.sat.err_iono(bad_epochs, :) = [];
                end
                if ~isempty(this.sat.solid_earth_corr)
                    this.sat.solid_earth_corr(bad_epochs, :) = [];
                end
                if ~isempty(this.sat.tot)
                    this.sat.tot(bad_epochs, :) = [];
                end
                if ~isempty(this.sat.az)
                    this.sat.az(bad_epochs, :) = [];
                end
                if ~isempty(this.sat.el)
                    this.sat.el(bad_epochs, :) = [];
                end
                if ~isempty(this.sat.res)
                    n_ep_res = size(this.sat.res,1);
                    bad_res = bad_epochs;
                    bad_res(bad_res > n_ep_res) = [];
                    this.sat.res(bad_res, :) = [];
                end
                if ~isempty(this.sat.slant_td)
                    this.sat.slant_td(bad_epochs, :) = [];
                end
            end
        end
        
        function remSat(this, go_id, prn)
            % remove satellites from receiver
            %
            % SYNTAX
            %   this.remSat(go_id)
            %   this.remSat(sys, prn);
            if nargin > 2 % interpreting as sys_c , prn
                go_id = this.getGoId(go_id, prn);
            end
            for s = 1 : numel(go_id)
                this.remObs(find(this.go_id == go_id(s))); %#ok<FNDSB>
            end
        end
        
%         function remBadPrObs(this, thr)
%             % remove bad pseudo-ranges
%             % and isolated observations
%             %
%             % INPUT
%             %   thr is a threshold in meters (default = 150)
%             %
%             % SYNTAX
%             %   this.remBadPrObs(thr)
%             if nargin == 1
%                 thr = 150; % meters
%             end
%             [pr, id_pr] = this.getPseudoRanges;
%             inan = isnan(pr);
%             pr_fill = simpleFill1D(pr, flagExpand(~inan, 5) &  inan);
%             med_pr = median(Core_Utils.diffAndPred(pr_fill,2),2,'omitnan');
%             out = abs(bsxfun(@minus, Core_Utils.diffAndPred(pr_fill, 2), med_pr)) > thr;
%             pr(out) = nan;
%             pr = zero2nan(Core_PP.remShortArcs(pr', 1))';
%             this.setPseudoRanges(pr, id_pr);
%             n_out = sum(out(:) & ~inan(:));
%             this.log.addMessage(this.log.indent(sprintf(' - %d code observations marked as outlier',n_out)));
%         end
%         
        function remBadPrObs(this, thr)
            % remove bad pseudo-ranges
            % and isolated observations
            %
            % INPUT
            %   thr is a threshold in meters (default = 150)
            %
            % SYNTAX
            %   this.remBadPrObs(thr)
            if nargin == 1
                thr = 150; % meters
            end
            [pr, id_pr] = this.getPseudoRanges;
            inan = isnan(pr);
            pr_fill = simpleFill1D(pr, flagExpand(~inan, 5) &  inan);
            
            pr_d3 = Core_Utils.diffAndPred(pr_fill,3);
            med_pr0 = median(pr_d3, 2,'omitnan');
            out = flagExpand(abs(bsxfun(@minus, pr_d3, med_pr0)) > thr, 2); % flagExpand -> beeing conservative, I prefer to flag more
            pr_fill(out) = nan;
            pr_fill = simpleFill1D(pr_fill, flagExpand(~inan, 5) &  inan);
            
            pr_d3 = Core_Utils.diffAndPred(bsxfun(@minus, Core_Utils.diffAndPred(pr_fill,2), cumsum(med_pr0)));
            med_pr = median(pr_d3, 2,'omitnan');
            out = flagExpand(abs(bsxfun(@minus, pr_d3, med_pr)) > thr/4, 2); % flagExpand -> beeing conservative, I prefer to flag more
            pr(out) = nan;
            % eliminate the last strong outliers
            out2 = flagExpand(abs(bsxfun(@minus, diff([nan(3, size(pr(1,:),2)); pr],3), median(diff([nan(3, size(pr(1,:),2)); pr],3),2,'omitnan'))) > thr / 5, 2);
            pr(out2) = nan;
            
            pr = zero2nan(Core_PP.remShortArcs(pr', 1))';
            this.setPseudoRanges(pr, id_pr);
            n_out = sum((out(:) | out2(:)) & ~inan(:));
            this.log.addMessage(this.log.indent(sprintf(' - %d code observations marked as outlier',n_out)));
        end
        
        function [obs, sys, prn, flag] = remUndCutOff(this, obs, sys, prn, flag, cut_off)
            %  remove obs under cut off
            for i = 1 : length(prn)
                go_id = this.getGoId(sys(i), prn(i)); % get go_id
                
                idx_obs = obs(i,:) ~= 0;
                this.updateAvailIndex(idx_obs, go_id);
                XS = this.getXSTxRot(go_id);
                if size(this.xyz,1) == 1
                    [~ , el] = this.computeAzimuthElevationXS(XS);
                else
                    [~ , el] = this.computeAzimuthElevationXS(XS,this.xyz(idx_obs,:));
                end
                
                idx_obs_f = find(idx_obs);
                el_idx = el < cut_off;
                idx_obs_f = idx_obs_f( el_idx );
                obs(i,idx_obs_f) = 0;
            end
            %%% remove possibly generated empty lines
            empty_idx = sum(obs > 0, 2) == 0;
            obs(empty_idx,:) = [];
            sys(empty_idx,:) = [];
            prn(empty_idx,:) = [];
            flag(empty_idx,:) = [];
        end
        
        function remEmptyObs(this)
            % remove empty obs lines
            empty_sat = sum(abs(this.obs),2) == 0;
            this.remObs(find(empty_sat));
        end
        
        function remBad(this)
            % Remove observation marked as bad in crx file and satellites
            % whose prn exceed the maximum prn (spare satellites, in maintenance, etc ..)
            % remove spare satellites
            % SYNTAX
            %   this.remBad();
            
            % remove bad epoch in crx
            this.log.addMarkedMessage('Removing observations marked as bad in Bernese .CRX file')
            [CRX, found] = load_crx(this.state.crx_dir, this.time, this.cc);
            if found
                for s = 1 : size(CRX,1)
                    c_sat_idx = this.go_id == s;
                    this.obs(c_sat_idx,CRX(s,:)) = 0;
                end
            end
            
            this.log.addMarkedMessage('Removing observations for which no ephemerid or clock is present')
            nan_coord = sum(isnan(this.sat.cs.coord) | this.sat.cs.coord == 0,3) > 0;
            nan_clock = isnan(this.sat.cs.clock) | this.sat.cs.clock == 0;
            first_epoch = this.time.first;
            coord_ref_time_diff = first_epoch - this.sat.cs.time_ref_coord;
            clock_ref_time_diff = first_epoch - this.sat.cs.time_ref_clock;
            for s = 1 : this.parent.cc.getMaxNumSat()
                o_idx = this.go_id == s;
                dnancoord = diff(nan_coord(:,s));
                st_idx = find(dnancoord == 1);
                end_idx = find(dnancoord == -1);
                if ~isempty(st_idx) || ~isempty(end_idx)
                    if isempty(st_idx)
                        st_idx = 1;
                    end
                    if isempty(end_idx)
                        end_idx = length(nan_coord);
                    end
                    if end_idx(1) < st_idx(1)
                        st_idx = [1; st_idx];
                    end
                    if st_idx(end) > end_idx(end)
                        end_idx = [end_idx ; length(nan_coord)];
                    end
                    for i = 1:length(st_idx)
                        is = st_idx(i);
                        ie = end_idx(i);
                        c_rate = this.sat.cs.coord_rate;
                        bad_ep_st = min(this.time.length,max(1, floor((-coord_ref_time_diff + is * c_rate - c_rate * 10)/this.getRate())));
                        bad_ep_en = max(1,min(this.time.length, ceil((-coord_ref_time_diff + ie * c_rate + c_rate * 10)/this.getRate())));
                        this.obs(o_idx , bad_ep_st : bad_ep_en) = 0;
                    end
                else
                    if nan_coord(1,s) == 1
                        this.obs(o_idx , :) = 0;
                    end
                end
                
                % removing near empty clock -> think a better solution
                dnanclock = diff(nan_clock(:,s));
                st_idx = find(dnanclock == 1);
                end_idx = find(dnanclock == -1);
                if ~isempty(st_idx) || ~isempty(end_idx)
                    if isempty(st_idx)
                        st_idx = 1;
                    end
                    if isempty(end_idx)
                        end_idx = length(nan_clock);
                    end
                    if end_idx(1) < st_idx(1)
                        st_idx = [1; st_idx];
                    end
                    if st_idx(end) > end_idx(end)
                        end_idx = [end_idx ; length(nan_clock)];
                    end
                    for i = 1:length(st_idx)
                        is = st_idx(i);
                        ie = end_idx(i);
                        c_rate = this.sat.cs.clock_rate;
                        bad_ep_st = min(this.time.length,max(1, floor((-clock_ref_time_diff + is*c_rate - c_rate * 1)/this.time.getRate())));
                        bad_ep_en = max(1,min(this.time.length, ceil((-clock_ref_time_diff + ie*c_rate + c_rate * 1)/this.time.getRate())));
                        this.obs(o_idx , bad_ep_st : bad_ep_en) = 0;
                    end
                else
                    if nan_clock(1,s) == 1
                        this.obs(o_idx , :) = 0;
                    end
                end
            end
            % remove moon midnight or shadow crossing epoch
            eclipsed = this.sat.cs.checkEclipseManouver(this.time);
            for i = 1: size(eclipsed,2)
                this.obs(this.go_id == i,eclipsed(:,i)~=0) = 0;
            end
            % check empty lines
            this.remEmptyObs();
            
        end
        
        function remUnderSnrThr(this, snr_thr)
            % remS observations with an SNR smaller than snr_thr
            %
            % SYNTAX
            %   this.remUnderSnrThr(snr_thr)
            
            if (nargin == 1)
                snr_thr = this.state.getSnrThr();
            end
            
            if snr_thr > 0
                [snr1, id_snr] = this.getObs('S1');
                
                snr1 = Receiver_Commons.smoothSatData([],[],zero2nan(snr1'), [], 'spline', 900 / this.getRate, 10); % smoothing SNR => to be improved
                id_snr = find(id_snr);
                if ~isempty(id_snr)
                    this.log.addMarkedMessage(sprintf('Removing data under %.1f dBHz', snr_thr));
                    n_rem = 0;
                    for s = 1 : numel(id_snr)
                        snr_test = snr1(:, s) < snr_thr;
                        this.obs(this.go_id == (this.go_id(id_snr(s))), snr_test) = 0;
                        n_rem = n_rem + sum(snr_test(:));
                    end
                    this.log.addMessage(this.log.indent(sprintf(' - %d observations under SNR threshold', n_rem)));
                end
            end
        end
        
        function remUnderCutOff(this, cut_off)
            % remS observations with an elevation lower than cut_off
            %
            % SYNTAX
            %   this.remUnderCutOff(cut_off)
            if nargin == 1
                cut_off = this.state.getCutOff;
            end
            this.log.addMessage(this.log.indent(sprintf('Removing observations under cut-off (%d degrees)', cut_off)));
            mask = this.sat.el > cut_off;
            this.obs = this.obs .* mask(:, this.go_id)';
            % Remove filtered satellites observations
            this.remObs(find(~any(this.obs(:,:)'))); %#ok<FNDSB>
        end
        
        function remShortArc(this, min_arc)
            % removes arc shorter than
            % SYNTAX
            %   this.remShortArc()
            if min_arc > 1
                this.log.addMarkedMessage(sprintf('Removing arcs shorter than %d epochs', 1 + 2 * ceil((min_arc - 1)/2)));
                
                [pr, id_pr] = this.getPseudoRanges();
                idx = ~isnan(pr);
                idx_s = flagShrink(idx, ceil((min_arc - 1)/2));
                idx_e = flagExpand(idx_s, ceil((min_arc - 1)/2));
                el_idx = xor(idx,idx_e);
                pr(el_idx) = NaN;
                this.setPseudoRanges(pr, id_pr);
                this.log.addMessage(this.log.indent(sprintf(' - %d code observations have been removed', sum(el_idx(:)))));
                
                [ph, wl, id_ph] = this.getPhases();
                idx = ~isnan(ph);
                idx_s = flagShrink(idx, ceil((min_arc - 1)/2));
                idx_e = flagExpand(idx_s, ceil((min_arc - 1)/2));
                el_idx = xor(idx,idx_e);
                ph(el_idx) = NaN;
                this.setPhases(ph, wl, id_ph);
                this.log.addMessage(this.log.indent(sprintf(' - %d phase observations have been removed', sum(el_idx(:)))));
            end
        end
        
        function addOutliers(this, id_ko, remove_short_arcs)
            if nargin < 3
                remove_short_arcs = false;
            end
            [ph, wl, id_ph] = this.getPhases();
            ph = zero2nan(this.obs(id_ph, :)');
            % Adding outliers
            if size(id_ko, 2) > size(this.sat.outliers_ph_by_ph, 2)
                id_ko = id_ko(:, this.go_id(id_ph));
            end
            this.sat.outliers_ph_by_ph(:,:) = (this.sat.outliers_ph_by_ph(:,:) | id_ko) & ~isnan(ph);
            if remove_short_arcs
                this.sat.outliers_ph_by_ph = flagMergeArcs(this.sat.outliers_ph_by_ph | isnan(ph), this.state.getMinArc) & ~isnan(ph); % mark short arcs
            end
            % Move cycle slips
            tmp = this.sat.outliers_ph_by_ph | isnan(ph);
            invalid_cs = this.sat.cicle_slip_ph_by_ph & tmp;
            for s = 1 : numel(unique(this.go_id(id_ph)))
                id_cs_ko = find(invalid_cs(:,s));
                for k = 1 : numel(id_cs_ko)
                    this.sat.cicle_slip_ph_by_ph(id_cs_ko(k), s) = false;
                    new_cs = id_cs_ko(k) + find(~tmp(id_cs_ko(k) : end, s), 1, 'first') -1;
                    if ~isempty(new_cs)
                        this.sat.cicle_slip_ph_by_ph(new_cs, s) = true;
                    end
                end
            end            
        end
        
        function updateDetectOutlierMarkCycleSlip(this)
            % After changing the observations Synth phases must be recomputed and
            % old outliers and cycle-slips removed before launching a new detection
            this.sat.outliers_ph_by_ph = false(size(this.sat.outliers_ph_by_ph));
            this.sat.cicle_slip_ph_by_ph = false(size(this.sat.cicle_slip_ph_by_ph));
            this.updateSyntPhases();
            this.detectOutlierMarkCycleSlip();
        end
        
        function detectOutlierMarkCycleSlip(this, flag_rem_dt)
            
            if nargin < 2 || isempty(flag_rem_dt)
                flag_rem_dt = true;
            end                
               
            this.log.addMarkedMessage('Cleaning observations');
            %% PARAMETRS
            ol_thr = 0.5; % outlier threshold
            cs_thr = 0.7*this.state.getCycleSlipThr(); % CYCLE SLIP THR
            sa_thr = this.state.getMinArc();  % short arc threshold
            
            %----------------------------
            % Outlier Detection
            %----------------------------
            
            % mark all as outlier and interpolate
            % get observed values
            [ph, wl, lid_ph] = this.getPhases;
            this.sat.outliers_ph_by_ph = false(size(ph));
            this.sat.cicle_slip_ph_by_ph = false(size(ph));
            
            this.log.addMessage(this.log.indent('Detect outlier candidates from residual phase time derivative'));
            % first time derivative
            phs = this.getSyntPhases;
            %%
            sensor_ph0 = Core_Utils.diffAndPred(ph - phs);
            
            % subtract median (clock error)
            if flag_rem_dt
                %sensor_ph = bsxfun(@minus, sensor_ph, getNrstZero(sensor_ph')');
                sensor_ph = bsxfun(@minus, sensor_ph0, median(sensor_ph0, 2, 'omitnan'));
                sensor_ph = bsxfun(@minus, sensor_ph, nan2zero(movmean(median(movmedian(sensor_ph, 5, 'omitnan'),2,'omitnan'),5, 'omitnan')));
                sensor_ph = bsxfun(@minus, sensor_ph, median(sensor_ph,'omitnan'));
            else
                sensor_ph = sensor_ph0;
            end
            
            % first rough out detection ------------------------------------------------------------------
            % This mean should be less than 10cm, otherwise the satellite have some very bad observations
            arc_mean = abs(mean(sensor_ph0,'omitnan'));
            bad_id = find(arc_mean > max(0.001, median(movstd(sensor_ph0, 5), 'omitnan')));
            % This mean should be less than 10cm, otherwise the satellite have some very bad observations
            arc_std = abs(std(sensor_ph0,'omitnan'));
            bad_id = unique([bad_id find(arc_std > 12*median(serialize(movstd(sensor_ph0, 5)), 'omitnan'))]);
            for i = 1 : numel(bad_id)
                % analize current arc
                sensor_tmp = sensor_ph(:, bad_id(i));
                % jump greater than 0.2 m (second derivative)
                tmp_out = abs(Core_Utils.diffAndPred(sensor_tmp)) > 0.2;
                sensor_tmp(tmp_out) = nan;
                % split the arc in continuous parts
                lim = getOutliers(~isnan(sensor_tmp));
                for l = 1 : size(lim, 1)
                    % if the arc have a median that is too big (> 0.2m) consider it all as outliers
                    if abs(median(sensor_tmp(lim(l,1) : lim(l,2)))) > 0.2
                        tmp_out(lim(l,1) : lim(l,2)) = true;
                    end
                end
                % if the sensor is greater than 1m consider the observation as outlier
                tmp_out = tmp_out | abs(sensor_tmp) > 1;
                this.sat.outliers_ph_by_ph(tmp_out, bad_id(i)) = true;
                sensor_ph0(tmp_out, bad_id(i)) = nan;
            end
            
            % recompute dt and sensor_ph
            if flag_rem_dt
                sensor_ph = bsxfun(@minus, sensor_ph0, median(sensor_ph0, 2, 'omitnan'));
                sensor_ph = bsxfun(@minus, sensor_ph, nan2zero(movmean(median(movmedian(sensor_ph, 5, 'omitnan'), 2,'omitnan'), 5, 'omitnan')));
                sensor_ph = bsxfun(@minus, sensor_ph, median(sensor_ph,'omitnan'));
            else
                sensor_ph = sensor_ph0;
            end
            
            % --------------------------------------------------------------------------------------------
            % detection on arc edges
            % flag out for more than 4 cm are bad phases,
            % expand them but consider outliers only what is out for more than 2 cm
            tmp_out = flagExpand(abs(sensor_ph) > 0.02, 8) & (abs(sensor_ph) > 0.01); % expand for a max of 8 epochs
            % keep only flags at the beginnig (10 epochs) of arcs (do not split arcs)
            tmp_out = tmp_out & flagExpand(isnan(sensor_ph), 10);
            
            % mark short arcs as outliers
            tmp_out = tmp_out | flagShrink(flagExpand(tmp_out, this.state.getMinArc), this.state.getMinArc);
            
            % save the outliers
            this.sat.outliers_ph_by_ph(tmp_out) = true;
            sensor_ph0(tmp_out) = nan;
            
            % recompute dt and sensor_ph
            sensor_ph = bsxfun(@minus, sensor_ph0, median(sensor_ph0, 2, 'omitnan'));
            
            % --------------------------------------------------------------------------------------------
            
            % test sensor variance
            tmp = sensor_ph(~isnan(sensor_ph));
            tmp(abs(tmp) > 4) = [];
            std_sensor = mean(movstd(tmp(:),900));
            %%
            % if the sensor is too noisy (i.e. the a-priori position is probably not very accurate)
            % use as a sensor the time second derivative
            if std_sensor > ol_thr
                this.log.addWarning('Bad dataset, switching to second time derivative for outlier detection');
                der = 2; % use second
                % try with second time derivative
                sensor_ph = Core_Utils.diffAndPred(ph - phs, der);
                sensor_ph = bsxfun(@minus, sensor_ph, median(sensor_ph, 2, 'omitnan'));
            else
                der = 1; % use first
            end
            
            sensor_ph = bsxfun(@minus, sensor_ph, nan2zero(movmean(median(movmedian(sensor_ph, 5, 'omitnan'), 2,'omitnan'), 5, 'omitnan')));
            sensor_ph = bsxfun(@minus, sensor_ph, median(sensor_ph,'omitnan'));
            
            % divide for wavelength (make it in cycles)
            sensor_ph = bsxfun(@rdivide, sensor_ph, wl');
            
            % outlier when they exceed 0.5 cycle
            poss_out_idx = abs(sensor_ph) > ol_thr / der;
            % take them off
            ph2 = ph;
            ph2(poss_out_idx) = nan;
            ph2(this.sat.outliers_ph_by_ph) = nan;
            
            sensor_ph0(poss_out_idx) = nan;
            if der > 1
                sensor_ph0 = Core_Utils.diffAndPred(sensor_ph0, der - 1);
            end
            
            %----------------------------
            % Cycle slip detection
            %----------------------------
            
            this.log.addMessage(this.log.indent('Detect cycle slips from residual phase time derivative'));
            
            ph2 = bsxfun(@minus, ph2, cumsum(nan2zero(median(sensor_ph0, 2, 'omitnan'))));
            % join the nan
            sensor_ph_cs = nan(size(sensor_ph));
            for o = 1 : size(ph2, 2)
                tmp_ph = ph2(:, o);
                ph_idx = not(isnan(tmp_ph));
                tmp_ph = tmp_ph(ph_idx);
                if ~isempty(tmp_ph)
                    sensor_ph_cs(ph_idx, o) = Core_Utils.diffAndPred(tmp_ph - phs(ph_idx,o), der);
                end
            end
            
            % subtract median
            sensor_ph_cs2 = bsxfun(@minus, sensor_ph_cs, nan2zero(movmean(median(movmedian(sensor_ph_cs, 5, 'omitnan'), 2, 'omitnan'), 5, 'omitnan')));
            sensor_ph_cs2 = bsxfun(@minus, sensor_ph_cs2, median(sensor_ph_cs2,'omitnan'));
            % divide for wavelength
            sensor_ph_cs2 = bsxfun(@rdivide, sensor_ph_cs2, wl');
            
            % find possible cycle slip
            % cycle slip when they exceed threhsold cycle
            poss_slip_idx = abs(sensor_ph_cs2) > cs_thr;
            
            %check if epoch before cycle slip can be restored
            poss_rest = [poss_slip_idx(2:end,:); zeros(1,size(poss_slip_idx,2))];
            poss_rest = poss_rest & poss_out_idx;
            poss_rest_line = sum(poss_rest,2);
            if sum(poss_rest_line) > 0
                poss_rest_line = poss_rest_line | [false; poss_rest_line(2:end)];
                ph_rest_lines = ph(poss_rest_line,:);
                synt_ph_rest_lines = phs(poss_rest_line,:);
                sensor_rst = Core_Utils.diffAndPred(ph_rest_lines - synt_ph_rest_lines);
                % subtract median
                sensor_rst = bsxfun(@minus, sensor_rst, median(sensor_rst, 2, 'omitnan'));
                % divide for wavelength
                sensor_rst = bsxfun(@rdivide, sensor_rst, wl');
                for i = 1:size(sensor_rst,2)
                    for c = find(poss_rest(:,i))'
                        if ~isempty(c)
                            idx = sum(poss_rest_line(1:c));
                            if abs(sensor_rst(idx,i)) < cs_thr
                                poss_out_idx(c,i) = false; %is not outlier
                                %move 1 step before the cycle slip index
                                poss_slip_idx(c+1,i) = false;
                                poss_slip_idx(c,i) = true;
                            end
                        end
                    end
                end
            end
            this.ph_idx = find(lid_ph);
            %-------------------------------------------------------
            % MELBOURNE WUBBENA based cycle slip detection
            %--------------------------------------------------------
            %             mw = this.getMelWub('1','2','G');
            %             omw = mw.obs./repmat(mw.wl,size(mw.obs,1),1);
            %             %m_omw = reshape(medfilt_mat(omw,10),size(omw));
            %             omw1 = Core_Utils.diffAndPred(zero2nan(omw),1);
            %             omw2 = Core_Utils.diffAndPred(zero2nan(omw),2);
            %             omw3 = Core_Utils.diffAndPred(zero2nan(omw),3);
            %             omw4 = Core_Utils.diffAndPred(zero2nan(omw),4);
            %             omw5 = Core_Utils.diffAndPred(zero2nan(omw),5);
            %             m_omw = (omw1 + omw2/2 + omw3/3 + omw4/4 + omw5/5) / 5;
            %             for o = 1 : length(mw.go_id)
            %                 go_id = mw.go_id(o);
            %                 idx_gi = this.go_id(id_ph_l) == go_id;
            %                 poss_slip_idx(abs(m_omw(:,o)) > 0.5,idx_gi) = 1;
            %             end
            
            %--------------------------------------------------------
            % SAFE CHOICE: if there is an hole
            %              put a cycle slip
            %--------------------------------------------------------
            for o = 1 : size(ph2,2)
                tmp_ph = ph2(:,o);
                % Remember that you lost more than 2 hour to find out why a cycle slip was not detected correctly
                ph_idx = flagMergeArcs(isnan(tmp_ph), 5); % (bigger than 5 epochs) => not marking a CS could be very very VERY bad
                %ph_idx  = isnan(tmp_ph);
                c_idx = [false ; diff(ph_idx) == -1];
                poss_slip_idx(c_idx,o) = 1;
            end
            
            % if majority of satellites jump set cycle slip on all
            n_obs_ep = sum(~isnan(ph2),2);
            all_but_one = (n_obs_ep - sum(poss_slip_idx,2)) < (0.7 * n_obs_ep) |  (n_obs_ep - sum(poss_slip_idx,2)) < 3;
            for c = find(all_but_one')
                poss_slip_idx(c,~isnan(ph2(c,:))) = 1;
            end
            
            
            this.sat.outliers_ph_by_ph = ((this.sat.outliers_ph_by_ph | poss_out_idx) & ~(poss_slip_idx));
            n_out = sum(this.sat.outliers_ph_by_ph(:));
            this.sat.cicle_slip_ph_by_ph = double(sparse(poss_slip_idx));
            % Remove short arcs            
            this.addOutliers(this.sat.outliers_ph_by_ph, true);
            if this.isMultiFreq % if the receiver is multifrequency there is the oppotunity to check again the cycle slip using geometry free and melbourne wubbena comniations
                [ph,wl,lid_ph] = this.getPhases;
                id_ph = find(lid_ph);
                go_id_ph = this.go_id(lid_ph);
                [pr,lid_pr] = this.getPseudoRanges;
                id_pr = find(lid_pr);
                go_id_pr = this.go_id(lid_pr);
                for g = unique(go_id_ph)'
                    % for each sat get all available observations and ge
                    % cycle slips
                    id_sat_ph = find(go_id_ph == g);
                    ph_sat = ph(:,id_sat_ph);
                    wl_sat = wl(id_sat_ph);
                    ph_sat_code = this.obs_code(id_ph(id_sat_ph),:);
                    u_fr_ph = unique(ph_sat_code(:,2));
                    n_fr_ph = zeros(size(u_fr_ph));
                    for i = 1 : length(u_fr_ph)
                        n_fr_ph(i) == sum(u_fr_ph == i);
                    end
                    
                    lid_sat_pr = go_id_pr == g;
                    pr_sat = pr(:,lid_sat_pr);
                    pr_sat_code = this.obs_code(id_pr(lid_sat_pr),:);
                    ph_sat_cs = this.sat.cicle_slip_ph_by_ph(:,id_sat_ph);
                    lid_cs_ep = sum(ph_sat_cs,2) > 0; % epoch with a cycle slip
                    id_cs_ep = find(lid_cs_ep);
                    n_epoch = size(this.sat.cicle_slip_ph_by_ph,1);
                    for ce = id_cs_ep' % for each epoch with a cycle slip
                        % 1) for each frequency check all tracking if one
                        % has jumped and the other no check if was really a
                        % cycle slip and repair
                        for f  = u_fr_ph'
                            id_fr_sat = find(ph_sat_code(:,2) == f);
                            cs_same_f = ph_sat_cs(ce,id_fr_sat);
                            if sum(cs_same_f) < length(cs_same_f) && sum(cs_same_f) > 0 % if not all have jumped
                                id_not_cs = find(~cs_same_f);
                                for s = find(cs_same_f)'
                                    cs_f = find(ph_sat_cs(:,id_fr_sat(s)));
                                    notcs_f = find(ph_sat_cs(:,id_not_cs(1))); % using first good frequency
                                    cs_bf = max([1; cs_f(cs_f < ce); notcs_f(notcs_f< ce)]);
                                    cs_aft = min([cs_f(cs_f > ce); notcs_f(notcs_f > ce); n_epoch]);
                                    id_1 = id_sat_ph(id_fr_sat(s));
                                    id_2 = id_sat_ph(id_fr_sat(id_not_cs(1)));
                                    jmp = mean(ph(ce:cs_aft,id_1) - ph(ce:cs_aft,id_2) ,'omitnan') - mean(ph(cs_bf:(ce-1),id_1) - ph(cs_bf:(ce-1),id_2),'omitnan');
                                    i_jmp = round(jmp/wl_sat(id_fr_sat(1)));
                                    if abs(jmp/wl_sat(id_fr_sat(1)) - i_jmp) < 0.05% very rough test for sgnificance
                                        this.sat.cicle_slip_ph_by_ph(ce,id_1) = false;% remove cycle slip
                                        if i_jmp ~= 0 
                                          ph(ce:end,id_1) = ph(ce:end,id_1) - i_jmp*wl_sat(id_fr_sat(1));
                                        end
                                    end
                                end
                            end
                        end  
                    end
%                     ph_sat_cs = this.sat.cicle_slip_ph_by_ph(:,id_sat_ph);
%                     lid_cs_ep = sum(ph_sat_cs,2) > 0; % epoch with a cycle slip
%                     id_cs_ep = find(lid_cs_ep);
%                      %2) check the geometry free and the melbourne
%                         %wubbena if one of the two detec a cycle slip then
%                         %is really a cycle slip otherwise remove it
%                     for ce = id_cs_ep' 
%                         fr_jmp = 
%                         for f  = 1 : length(u_fr_ph)
%                         end
%                     end
%                     
%                     
                end
                this.setPhases(ph,wl,lid_ph); % ste back phases
                
            end
            this.log.addMessage(this.log.indent(sprintf(' - %d phase observations marked as outlier',n_out)));
        end
        
        function cycleSlipPPPres(this)
            sensor = Core_Utils.diffAndPred(this.sat.res);
            ph_idx =  this.obs_code(:,1) == 'L';
            idx = abs(sensor) > 0.03;
            for i = 1 : size(sensor,2)
                sat_idx = this.go_id(ph_idx) == i;
                this.sat.cicle_slip_ph_by_ph(idx(:,i), :) = 1;
            end
        end
        
        function tryCycleSlipRepair(this)
            % Cycle slip repair
            %
            % window used to estimate cycle slip
            % linear time
            lin_time = 900; %single diffrence is linear in 15 minutes
            max_window = 600; %maximum windows allowed (for computational reason)
            win_size = min(max_window,ceil(lin_time / this.getRate()/2)*2); %force even
            
            poss_out_idx = this.sat.outliers_ph_by_ph;
            poss_slip_idx = this.sat.cicle_slip_ph_by_ph;
            
            [ph, ~, id_ph_l] = this.getPhases();
            id_ph = find(id_ph_l);
            synt_ph = this.getSyntPhases();
            d_no_out = (ph - synt_ph )./ repmat(this.wl(id_ph_l)',size(ph,1),1);
            n_ep = this.time.length;
            poss_slip_idx = double(poss_slip_idx);
            n_cycleslip = 0;
            n_repaired = 0;
            jmps = [];
            for p = 1:size(poss_slip_idx,2)
                c_slip = find(poss_slip_idx(:,p)' == 1);
                for c = c_slip
                    n_cycleslip = n_cycleslip + 1;
                    slip_bf = find(poss_slip_idx(max(1,c - win_size /2 ): c-1, p),1,'last');
                    if isempty(slip_bf)
                        slip_bf = 0;
                    end
                    st_wind_idx = max(1,c - win_size /2 + slip_bf);
                    slip_aft = find(poss_slip_idx(c :min( c + win_size / 2,n_ep), p),1,'first');
                    if isempty(slip_aft)
                        slip_aft = 0;
                    end
                    end_wind_idx = min(c + win_size /2 - slip_bf -1,n_ep);
                    jmp_idx =  win_size /2 - slip_bf +1;
                    
                    % find best master before
                    idx_other_l = 1:size(poss_slip_idx,2) ~= p;
                    idx_win_bf = poss_slip_idx(st_wind_idx : c -1 , idx_other_l) ;
                    best_cs = min(idx_win_bf .* repmat([1:(c-st_wind_idx)]',1,sum(idx_other_l))); %find other arc with farerer cycle slip
                    poss_mst_bf =~isnan(d_no_out(st_wind_idx : c -1 , idx_other_l));
                    for j = 1 : length(best_cs)
                        poss_mst_bf(1:best_cs(j),j) = false;
                    end
                    num_us_ep_bf = sum(poss_mst_bf); % number of usable epoch befor
                    data_sorted = sort(num_us_ep_bf,'descend');
                    [~, rnk_bf] = ismember(num_us_ep_bf,data_sorted);
                    
                    % find best master after
                    idx_win_aft = poss_slip_idx(c : end_wind_idx , idx_other_l) ;
                    best_cs = min(idx_win_aft .* repmat([1:(end_wind_idx -c +1)]',1,sum(idx_other_l))); %find other arc with farerer cycle slip
                    poss_mst_aft =~isnan(d_no_out(c : end_wind_idx, idx_other_l));
                    for j = 1 : length(best_cs)
                        poss_mst_aft(1:best_cs(j),j) = false;
                    end
                    num_us_ep_aft = sum(poss_mst_aft); % number of usable epoch befor
                    data_sorted = sort(num_us_ep_aft,'descend');
                    [~, rnk_aft] = ismember(num_us_ep_aft,data_sorted);
                    
                    
                    idx_other = find(idx_other_l);
                    
                    %decide which arc to use
                    bst_1 = find(rnk_bf == 1  & rnk_aft == 1,1,'first');
                    if isempty(bst_1)
                        bst_1 = find(rnk_bf == 1 ,1,'first');
                        bst_2 = find(rnk_aft == 1,1,'first');
                        same_slope = false;
                    else
                        bst_2 = bst_1;
                        same_slope = true;
                    end
                    
                    s_diff = d_no_out(st_wind_idx : end_wind_idx, p) - [d_no_out(st_wind_idx : c -1, idx_other(bst_1)); d_no_out(c : end_wind_idx, idx_other(bst_2))];
                    jmp = nan;
                    if sum(~isnan(s_diff(1:jmp_idx-1))) > 5 & sum(~isnan(s_diff(jmp_idx:end))) > 5
                        jmp = estimateJump(s_diff, jmp_idx,same_slope,'median');
                        jmps= [jmps ; jmp];
                    end
                    
                    %{
                    ph_piv = d_no_out(st_wind_idx : end_wind_idx,p);
                    usable_s = sum(poss_mst_bf) > 0 & sum(poss_mst_aft);
                    ph_other = d_no_out(st_wind_idx : end_wind_idx,idx_other_l);
                    ph_other([~poss_mst_bf ;~poss_mst_aft]) = nan;
                    ph_other(:, ~usable_s) = [];

                    s_diff = ph_other - repmat(ph_piv,1,size(ph_other,2));
                    %}
                    % repair
                    % TO DO half cycle
                    if ~isnan(jmp)
                        this.obs(id_ph(p),c:end) = nan2zero(zero2nan(this.obs(id_ph(p),c:end)) - round(jmp));
                    end
                    if false %abs(jmp -round(jmp)) < 0.01
                        poss_slip_idx(c, p) = - 1;
                        n_repaired = n_repaired +1;
                    else
                        poss_slip_idx(c, p) =   1;
                    end
                end
            end
            
            this.log.addMessage(this.log.indent(sprintf(' - %d of %d cycle slip repaired',n_repaired,n_cycleslip)));
            
            this.sat.cicle_slip_ph_by_ph = poss_slip_idx;
            
            % save index into object
            
        end
        
        function importRinex(this, file_name, t_start, t_stop, rate)
            % Parses RINEX observation files.
            %
            % SYNTAX
            %   this.importRinex(file_name, <t_start>, <t_stop>, <rate>)
            %
            % INPUT
            %   filename = RINEX observation file(s)
            %
            % OUTPUT
            %   pr1 = code observation (L1 carrier)
            %   ph1 = phase observation (L1 carrier)
            %   pr2 = code observation (L2 carrier)
            %   ph2 = phase observation (L2 carrier)
            %   dop1 = Doppler observation (L1 carrier)
            %   dop2 = Doppler observation (L2 carrier)
            %   snr1 = signal-to-noise ratio (L1 carrier)
            %   snr2 = signal-to-noise ratio (L2 carrier)
            %   time = receiver seconds-of-week
            %   week = GPS week
            %   date = date (year,month,day,hour,minute,second)
            %   pos = rover approximate position
            %   interval = observation time interval [s]
            %   antoff = antenna offset [m]
            %   antmod = antenna model [string]
            %   codeC1 = boolean variable to notify if the C1 code is used instead of P1
            %   marker = marker name [string]
            if nargin < 3 || isempty(t_start)
                t_start = GPS_Time(0);
            end
            if nargin < 4 || isempty(t_stop)
                t_stop = GPS_Time(800000); % 2190/04/28 an epoch very far away
            end
            
            if nargin < 5
                rate = [];
            end
            
            t0 = tic;
            
            this.log.addMarkedMessage('Reading observations...');
            this.log.newLine();
            
            this.file =  File_Rinex(file_name, 9);
            
            if this.file.isValid()
                this.log.addMessage(sprintf('Opening file %s for reading', file_name), 100);
                % open RINEX observation file
                fid = fopen(file_name,'r');
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
                
                % importing header informations
                eoh = this.file.eoh;
                this.parseRinHead(txt, lim, eoh);
                
                if (this.rin_type < 3)
                    % considering rinex 2
                    this.parseRin2Data(txt, has_cr, lim, eoh, t_start, t_stop, rate);
                else
                    % considering rinex 3
                    this.parseRin3Data(txt, lim, eoh, t_start, t_stop, rate);
                end
                
                % guess rinex3 flag for incomplete flag (probably coming from rinex2 or converted rinex2 -> rinex3)
                % WARNING!! (C/A) + (P2-P1) semi codeless tracking (flag C2D) receiver not supporter (in rinex 2) convert them
                % using cc2noncc converter https://github.com/ianmartin/cc2noncc (not tested)
                
                % GPS C1 -> C1C
                idx = this.findObservableByFlag('C1 ','G');
                this.obs_code(idx,:) = repmat('C1C',length(idx),1);
                % GPS C2 -> C2C
                idx = this.findObservableByFlag('C2 ','G');
                this.obs_code(idx,:) = repmat('C2C',length(idx),1);
                % GPS L1 -> L1C
                idx = this.findObservableByFlag('L1 ','G');
                this.obs_code(idx,:) = repmat('L1C',length(idx),1);
                % GPS L2 -> L2W
                idx = this.findObservableByFlag('L2 ','G');
                this.obs_code(idx,:) = repmat('L2W',length(idx),1);
                % GPS C5 -> C5I
                idx = this.findObservableByFlag('C5 ','G');
                this.obs_code(idx,:) = repmat('C5I',length(idx),1);
                % GPS L5 -> L5I
                idx = this.findObservableByFlag('L5 ','G');
                this.obs_code(idx,:) = repmat('L5I',length(idx),1);
                % GPS P1 -> C1W
                idx = this.findObservableByFlag('P1 ','G');
                this.obs_code(idx,:) = repmat('C1W',length(idx),1);
                % GPS P2 -> C2W
                idx = this.findObservableByFlag('P2 ','G');
                this.obs_code(idx,:) = repmat('C2W',length(idx),1);
                % GLONASS C1 -> C1C
                idx = this.findObservableByFlag('C1 ','R');
                this.obs_code(idx,:) = repmat('C1C',length(idx),1);
                % GLONASS C2 -> C2C
                idx = this.findObservableByFlag('C2 ','R');
                this.obs_code(idx,:) = repmat('C2C',length(idx),1);
                % GLONASS C1 -> C1C
                idx = this.findObservableByFlag('L1 ','R');
                this.obs_code(idx,:) = repmat('L1C',length(idx),1);
                % GLONASS C2 -> C2C
                idx = this.findObservableByFlag('L2 ','R');
                this.obs_code(idx,:) = repmat('L2C',length(idx),1);
                % GLONASS P1 -> C1P
                idx = this.findObservableByFlag('P1 ','R');
                this.obs_code(idx,:) = repmat('C1P',length(idx),1);
                % GLONASS P2 -> C2P
                idx = this.findObservableByFlag('P2 ','R');
                this.obs_code(idx,:) = repmat('C2P',length(idx),1);
                % GALILEO C1 -> C1A
                idx = this.findObservableByFlag('C1 ','E');
                this.obs_code(idx,:) = repmat('C1A',length(idx),1);
                % GALILEO L1 -> L1A
                idx = this.findObservableByFlag('L1 ','E');
                this.obs_code(idx,:) = repmat('L1A',length(idx),1);
                % other flags to be investiagated
                
                this.log.addMessage(sprintf('Parsing completed in %.2f seconds', toc(t0)));
                this.log.newLine();
                
                % Compute the other useful status array of the receiver object
                if ~isempty(this.obs)
                    this.updateStatus();
                end
                
                % remove empty observables
                this.remObs(~this.active_ids);
                % remove empty sets very useful when reading RINEX 2
                % multi-constellations files
                if ~isempty(this.obs)
                    this.remObs(~(any(this.obs')));
                    % remove unselected observations
                    u_sys_c = unique(this.system);
                    for i = 1 : length(u_sys_c)
                        sys_c = u_sys_c(i);
                        ss = this.cc.getSys(sys_c);
                        active_band = ss.CODE_RIN3_2BAND(~ss.flag_f);
                        for j = 1 : length(active_band)
                            idx = this.findObservableByFlag(['?' active_band(j) '?'] ,sys_c);
                            this.remObs(idx);
                        end
                    end
                end
            end
        end
        
        function importAntModel(this)
            % Load and parse the antenna (ATX) file as specified into settings
            % SYNTAX
            %   this.importAntModel
            filename_pcv = this.state.getAtxFile;
            fnp = File_Name_Processor();
            this.log.addMessage(this.log.indent(sprintf('Opening file %s for reading', fnp.getFileName(filename_pcv))));
            pcv =  Core_Utils.readAntennaPCV(filename_pcv, {this.parent.ant_type});
            if pcv.available == 0 
                ant_parts = strsplit(this.parent.ant_type);
                if ~isempty(ant_parts{1})
                    ant_parts{2} = 'NONE';
                    ant_name = repmat(' ',1,20);
                    ant_name(1:length(ant_parts{1})) = ant_parts{1};
                    ant_name((end +1 -length(ant_parts{2})):end) = ant_parts{2};
                    this.log.addMessage(this.log.indent(sprintf('looking for antenna without radome: %s',ant_name)));
                    pcv = Core_Utils.readAntennaPCV(filename_pcv, {ant_name});
                end
            end
            this.pcv = pcv;
        end
        
        function importOceanLoading(this)
            % load ocean loading displcement matrix from
            %ocean_loading.blq if satation is present
            [this.ocean_load_disp, found] = load_BLQ( this.state.getOceanFile,{this.parent.getMarkerName4Ch});
            if not(found) && ~strcmpi(this.parent.getMarkerName4Ch, this.parent.getMarkerName)
                [this.ocean_load_disp, found] = load_BLQ( this.state.getOceanFile,{this.parent.getMarkerName});
            end
            if found == 0
                this.ocean_load_disp = -1; %ocean loading parameters not found
                this.log.addWarning('Ocean loading parameters not found.');
                this.parent.getChalmersString();
            end
        end
        
        function importMeteoData(this)
            % load meteo data from Meteo Network object
            %and get a virtual station at receiver positions
            mn = Core.getMeteoNetwork();
            if ~isempty(mn) && ~isempty(mn.mds)
                this.log.addMarkedMessage('importing meteo data');
                this.meteo_data = mn.getVMS(this.parent.marker_name, this.xyz, this.getNominalTime);
            end
        end
        
        function parseRinHead(this, txt, lim, eoh)
            % Parse the header of the Observation Rinex file
            % SYNTAX
            %    this.parseRinHead(txt, nl)
            % INPUT
            %    txt    raw txt of the RINEX
            %    lim    indexes to determine start-stop of a line in "txt"  [n_line x 2/<3>]
            %    eoh    end of header line
            
            h_std{1} = 'RINEX VERSION / TYPE';                  %  1
            h_std{2} = 'PGM / RUN BY / DATE';                   %  2
            h_std{3} = 'MARKER NAME';                           %  3
            h_std{4} = 'OBSERVER / AGENCY';                     %  4
            h_std{5} = 'REC # / TYPE / VERS';                   %  5
            h_std{6} = 'ANT # / TYPE';                          %  6
            h_std{7} = 'APPROX POSITION XYZ';                   %  7
            h_std{8} = 'ANTENNA: DELTA H/E/N';                  %  8
            h_std{9} = 'TIME OF FIRST OBS';                     %  9
            
            h_opt{1} = 'MARKER NUMBER';                         % 10
            h_opt{2} = 'INTERVAL';                              % 11
            h_opt{3} = 'TIME OF LAST OBS';                      % 12
            h_opt{4} = 'LEAP SECONDS';                          % 13
            h_opt{5} = '# OF SATELLITES';                       % 14
            h_opt{6} = 'PRN / # OF OBS';                        % 15
            
            h_rin2_only{1} = '# / TYPES OF OBSERV';             % 16
            h_rin2_only{2} = 'WAVELENGTH FACT L1/2';            % 17
            
            h_rin3_only{1} = 'MARKER TYPE';                     % 18
            h_rin3_only{2} = 'SYS / # / OBS TYPES';             % 19
            h_rin3_only{3} = 'SYS / PHASE SHIFT';               % 20
            h_rin3_only{4} = 'GLONASS SLOT / FRQ #';            % 21
            h_rin3_only{5} = 'GLONASS COD/PHS/BIS';             % 22
            
            h_opt_rin3_only{1} = 'ANTENNA: DELTA X/Y/Z';        % 23
            h_opt_rin3_only{2} = 'ANTENNA:PHASECENTER';         % 24
            h_opt_rin3_only{3} = 'ANTENNA: B.SIGHT XYZ';        % 25
            h_opt_rin3_only{4} = 'ANTENNA: ZERODIR AZI';        % 26
            h_opt_rin3_only{5} = 'ANTENNA: ZERODIR XYZ';        % 27
            h_opt_rin3_only{6} = 'CENTER OF MASS: XYZ';         % 28
            h_opt_rin3_only{7} = 'SIGNAL STRENGTH UNIT';        % 29
            h_opt_rin3_only{8} = 'RCV CLOCK OFFS APPL';         % 30
            h_opt_rin3_only{9} = 'SYS / DCBS APPLIED';          % 31
            h_opt_rin3_only{10} = 'SYS / PCVS APPLIED';         % 32
            h_opt_rin3_only{11} = 'SYS / SCALE FACTOR';         % 33
            
            head_field = {h_std{:} h_opt{:} h_rin2_only{:} h_rin3_only{:} h_opt_rin3_only{:}}';
            
            % read RINEX type 3 or 2 ---------------------------------------------------------------------------------------------------------------------------
            l = 0;
            type_found = false;
            while ~type_found && l < eoh
                l = l + 1;
                if strcmp(strtrim(txt((lim(l,1) + 60) : lim(l,2))), h_std{1})
                    type_found = true;
                    dataset = textscan(txt(lim(l,1):lim(l,2)), '%f%c%18c%c');
                end
            end
            this.rin_type = dataset{1};
            this.rinex_ss = dataset{4};
            if dataset{2} == 'O'
                if (this.rin_type < 3)
                    if (dataset{4} ~= 'G')
                        % GPS only RINEX2 - mixed or glonass -> actually not working
                        %throw(MException('VerifyINPUTInvalidObservationFile', 'RINEX2 is supported for GPS only dataset, please use a RINEX3 file '));
                    else
                        % GPS only RINEX2 -> ok
                    end
                else
                    % RINEX 3 file -> ok
                end
            else
                throw(MException('VerifyINPUTInvalidObservationFile', 'This observation RINEX does not contain observations'));
            end
            
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
            
            % reading parameters -------------------------------------------------------------------------------------------------------------------------------
            
            % 1) 'RINEX VERSION / TYPE'
            % already parsed
            % 2) 'PGM / RUN BY / DATE'
            % ignoring
            % 3) 'MARKER NAME'
            fln = find(line2head == 3, 1, 'first'); % get field line
            if isempty(fln)
                this.parent.marker_name = 'NO_NAME';
            else
                this.parent.marker_name = strtrim(txt(lim(fln, 1) + (0:59)));
            end
            % 4) 'OBSERVER / AGENCY'
            fln = find(line2head == 4, 1, 'first'); % get field line
            if isempty(fln)
                this.parent.observer = 'goGPS';
                this.parent.agency = 'Unknown';
            else
                this.parent.observer = strtrim(txt(lim(fln, 1) + (0:19)));
                this.parent.agency = strtrim(txt(lim(fln, 1) + (20:39)));
            end
            % 5) 'REC # / TYPE / VERS'
            fln = find(line2head == 5, 1, 'first'); % get field line
            if isempty(fln)
                this.parent.number   = '000';
                this.parent.type     = 'unknown';
                this.parent.version  = '000';
            else
                this.parent.number = strtrim(txt(lim(fln, 1) + (0:19)));
                this.parent.type = strtrim(txt(lim(fln, 1) + (20:39)));
                this.parent.version = strtrim(txt(lim(fln, 1) + (40:59)));
            end
            % ignoring
            % 6) 'ANT # / TYPE'
            fln = find(line2head == 6, 1, 'first'); % get field line
            if isempty(fln)
                this.parent.ant = '';
                this.parent.ant_type = '';
            else
                this.parent.ant = strtrim(txt(lim(fln, 1) + (0:19)));
                this.parent.ant_type = strtrim(txt(lim(fln, 1) + (20:39)));
            end
            % 7) 'APPROX POSITION XYZ'
            fln = find(line2head == 7, 1, 'first'); % get field line
            if isempty(fln)
                this.xyz_approx = [0 0 0];
                this.xyz = [0 0 0];
            else
                tmp = sscanf(txt(lim(fln, 1) + (0:41)),'%f')';                                               % read value
                this.xyz_approx = iif(isempty(tmp) || ~isnumeric(tmp) || (numel(tmp) ~= 3), [0 0 0], tmp);          % check value integrity
                this.xyz = this.xyz_approx;
            end
            % 8) 'ANTENNA: DELTA H/E/N'
            fln = find(line2head == 8, 1, 'first'); % get field line
            if isempty(fln)
                this.parent.ant_delta_h = 0;
                this.parent.ant_delta_en = [0 0];
            else
                tmp = sscanf(txt(lim(fln, 1) + (0:13)),'%f')';                                                % read value
                this.parent.ant_delta_h = iif(isempty(tmp) || ~isnumeric(tmp) || (numel(tmp) ~= 1), 0, tmp);         % check value integrity
                tmp = sscanf(txt(lim(fln, 1) + (14:41)),'%f')';                                               % read value
                this.parent.ant_delta_en = iif(isempty(tmp) || ~isnumeric(tmp) || (numel(tmp) ~= 2), [0 0], tmp);    % check value integrity
            end
            % 9) 'TIME OF FIRST OBS'
            % ignoring it's already in this.file.first_epoch, but the code to read it is the following
            %fln = find(line2head == 9, 1, 'first'); % get field line
            %tmp = sscanf(txt(lim(fln, 1) + (0:42)),'%f')';
            %first_epoch = iif(isempty(tmp) || ~isnumeric(tmp) || (numel(tmp) ~= 6), this.file.first_epoch, GPS_Time(tmp));    % check value integrity
            %first_epoch.setGPS(~strcmp(txt(lim(fln, 1) + (48:50)),'GLO'));
            % 10) 'MARKER NUMBER'
            % ignoring
            % 11) INTERVAL
            fln = find(line2head == 11, 1, 'first'); % get field line
            if isempty(fln)
                this.rate = 0; % If it's zero it'll be necessary to compute it
            else
                tmp = sscanf(txt(lim(fln, 1) + (0:9)),'%f')';                                  % read value
                this.rate = iif(isempty(tmp) || ~isnumeric(tmp) || (numel(tmp) ~= 1), 0, tmp);  % check value integrity
            end
            % 12) TIME OF LAST OBS
            % ignoring it's already in this.file.last_epoch, but the code to read it is the following
            % fln = find(line2head == 12, 1, 'first'); % get field line
            % tmp = sscanf(txt(lim(fln, 1) + (0:42)),'%f')';
            % last_epoch = iif(isempty(tmp) || ~isnumeric(tmp) || (numel(tmp) ~= 6), this.file.first_epoch, GPS_Time(tmp));    % check value integrity
            % last_epoch.setGPS(~strcmp(txt(lim(fln, 1) + (48:50)),'GLO'));
            % 13) LEAP SECONDS
            % ignoring
            % 14) # OF SATELLITES
            fln = find(line2head == 14, 1, 'first'); % get field line
            if isempty(fln)
                this.n_sat = this.cc.getNumSat(); % If it's zero it'll be necessary to compute it
            else
                tmp = sscanf(txt(lim(fln, 1) + (0:5)),'%f')';                                  % read value
                this.n_sat = iif(isempty(tmp) || ~isnumeric(tmp) || (numel(tmp) ~= 1), this.cc.getNumSat(), tmp);  % check value integrity
            end
            % 15) PRN / # OF OBS            % ignoring
            % 16) # / TYPES OF OBSERV
            if this.rin_type < 3
                fln = find(line2head == 16); % get field line
                rin_obs_code = [];
                if ~isempty(fln)
                    n_obs = sscanf(txt(lim(fln(1), 1) + (3:5)),'%d');
                    l = 1;
                    while l <= numel(fln)
                        n_line = ceil(n_obs / 9);
                        l_offset = 0;
                        while l_offset < n_line
                            rin_obs_code = [rin_obs_code sscanf(txt(lim(fln(l + l_offset), 1) + (6:59)),'%s')];
                            l_offset = l_offset + 1;
                        end
                        l = l + l_offset;
                    end
                    rin_obs_code = serialize([reshape(rin_obs_code, 2, numel(rin_obs_code) / 2); ' ' * ones(1, numel(rin_obs_code) / 2)])';
                end
                this.rin_obs_code = struct('G', rin_obs_code, 'R', rin_obs_code, 'E', rin_obs_code, 'J', rin_obs_code, 'C', rin_obs_code, 'I', rin_obs_code, 'S', rin_obs_code);
                
            end
            % 17) WAVELENGTH FACT L1/2
            % ignoring
            % 18) MARKER TYPE
            % Assuming non geodetic type as default
            this.parent.marker_type = 'NON-GEODETIC';
            fln = find(line2head == 18, 1, 'first'); % get field line
            if ~isempty(fln)
                this.parent.marker_type = strtrim(txt(lim(fln, 1) + (0:19)));
            end
            
            % 19) SYS / # / OBS TYPES
            if this.rin_type >= 3
                fln = find(line2head == 19); % get field lines
                this.rin_obs_code = struct('G',[],'R',[],'E',[],'J',[],'C',[],'I',[],'S',[]);
                if ~isempty(fln)
                    l = 1;
                    while l <= numel(fln)
                        sys = char(txt(lim(fln(l), 1)));
                        n_obs = sscanf(txt(lim(fln(l), 1) + (3:5)),'%d');
                        n_line = ceil(n_obs / 13);
                        l_offset = 0;
                        while l_offset < n_line
                            obs_code_text = txt(lim(fln(l + l_offset), 1) + (7:59));
                            idx_code = true(length(obs_code_text),1);
                            idx_code(4:4:(floor(length(obs_code_text)/4)*4)) = false; % inedx to take only valid columns
                            obs_code_temp = obs_code_text(idx_code');
                            obs_code_temp((ceil(max(find(obs_code_temp ~= ' '))/3)*3 +1 ):end) = []; %delete empty lines at the end
                            this.rin_obs_code.(sys) = [this.rin_obs_code.(sys) obs_code_temp];
                            
                            l_offset = l_offset + 1;
                        end
                        l = l + l_offset;
                    end
                end
                if ~isempty(strfind(this.rin_obs_code.C, '1'))
                    this.rin_obs_code.c(this.rin_obs_code.C == '1') = '2';
                    this.log.addWarning('BeiDou band 1 is now defined as 2 -> Automatically converting the observation codes of the RINEX!');
                end
            end
            % 20) SYS / PHASE SHIFT
            fln = find(line2head == 20); % get field line
            if this.rin_type < 3
                this.ph_shift = struct('G', zeros(numel(this.rin_obs_code.G) / 3, 1));
            else
                this.ph_shift = struct('G',[],'R',[],'E',[],'J',[],'C',[],'I',[],'S',[]);
                for l = 1 : numel(fln)
                    if txt(lim(fln(l), 1)) ~= ' ' % ignoring phase shif only on subset of satellites
                        sys = char(txt(lim(fln(l), 1)));
                        
                        rin_obs_code = txt(lim(fln(l), 1) + (2:4));
                        obs_id = (strfind(this.rin_obs_code.(sys), rin_obs_code) - 1) / 3 + 1;
                        if isempty(this.ph_shift.(sys))
                            this.ph_shift.(sys) = zeros(numel(this.rin_obs_code.(sys)) / 3, 1);
                        end
                        shift = sscanf(txt(lim(fln(l), 1) + (6:14)),'%f');
                        if ~isempty(shift)
                            this.ph_shift.(sys)(obs_id) = shift;
                        end
                    end
                end
            end
            % 21) GLONASS SLOT / FRQ #
            % ignoring
            % 22) GLONASS COD/PHS/BIS
            % ignoring
            % 23) ANTENNA: DELTA X/Y/Z
            % ignoring
            % 24) ANTENNA:PHASECENTER
            % ignoring
            % 25) ANTENNA: B.SIGHT XYZ
            % ignoring
            % 26) ANTENNA: ZERODIR AZI
            % ignoring
            % 27) ANTENNA: ZERODIR XYZ
            % ignoring
            % 28) CENTER OF MASS: XYZ
            % ignoring
            % 29) SIGNAL STRENGTH UNIT
            % ignoring
            % 30) RCV CLOCK OFFS APPL
            % ignoring
            % 31) SYS / DCBS APPLIED
            % ignoring
            % 32) SYS / PCVS APPLIED
            % ignoring
            % 33) SYS / SCALE FACTOR
            % ignoring
            
        end
        
        function parseRin2Data(this, txt, has_cr, lim, eoh, t_start, t_stop, rate)
            % Parse the data part of a RINEX 2 file -  the header must already be parsed
            % SYNTAX this.parseRin2Data(txt, lim, eoh, <t_start>, <t_stop>)
            % remove comment line from lim
            if nargin < 6
                t_start = GPS_Time(0);
                t_stop = GPS_Time(800000); % 2190/04/28 an epoch very far away
            end
            if nargin < 7
                rate = [];
            end
            comment_pos = repmat(lim(:,1),1,7) + repmat(60:66, size(lim,1), 1);
            % avoid searching out of txt boundaries
            id_ko = find(comment_pos(:,end) > numel(txt), 1, 'first');
            if not(isempty(id_ko))
                comment_pos(id_ko : end, :) = [];
            end
            comment_line = sum(txt(comment_pos) == repmat('COMMENT', size(comment_pos, 1), 1),2) == 7;
            comment_line(1:eoh) = false;
            lim(comment_line,:) = [];
            if lim(end,3) < 32
                txt = [txt repmat(' ',1,32 - lim(end,3))];
            end
            % find all the observation lines
            t_line = find([false(eoh, 1); (txt(lim(eoh+1:end,1) + 2) ~= ' ')' & (txt(lim(eoh+1:end,1) + 3) == ' ')' & ...
                (txt(lim(eoh+1:end,1) + 28) <= '1')' & ... % discard any problematic event
                lim(eoh+1:end,3) > 25]);
            n_epo = numel(t_line);
            % extract all the epoch lines
            string_time = txt(repmat(lim(t_line,1),1,25) + repmat(1:25, n_epo, 1))';
            % convert the times into a 6 col time
            date = cell2mat(textscan(string_time,'%2f %2f %2f %2f %2f %10.7f'));
            after_70 = (date(:,1) < 70); date(:, 1) = date(:, 1) + 1900 + after_70 * 100; % convert to 4 digits
            % import it as a GPS_Time obj
            this.time = GPS_Time(date, [], this.file.first_epoch.is_gps);
            to_keep_ep = this.time > t_start & this.time < t_stop;
            this.time.remEpoch(~to_keep_ep);
            t_line(~to_keep_ep) = [];
            if ~isempty(t_line) && ~isempty(rate)
                nominal = this.getNominalTime();
                nominal_ss = this.time.getNominalTime(rate, true);
                to_discard = true(this.time.length, 1);
                % Find the valid epoch that are close to the nominal at the requested rate (aka do not read the entire file)
                t_rel = nominal.getRefTime(floor(nominal.first.getMatlabTime));
                t_rel_ss = nominal_ss.getRefTime(floor(nominal.first.getMatlabTime));
                [~, to_keep_ep] = intersect(round(t_rel * 1e5), round(t_rel_ss * 1e5));
                to_discard(to_keep_ep) = false;
                this.time.remEpoch(to_discard);
                t_line(to_discard) = [];
            end
            if ~isempty(t_line)
                n_epo = numel(t_line);
                
                this.rate = this.time.getRate();
                % get number of sat per epoch
                this.n_spe = sscanf(txt(repmat(lim(t_line,1),1,3) + repmat(29:31, n_epo, 1))', '%d');
                
                all_sat = [];
                for e = 1 : n_epo
                    n_sat = this.n_spe(e);
                    sat = serialize(txt(lim(t_line(e),1) + repmat((0 : ceil(this.n_spe(e) / 12) - 1)' * 69, 1, 36) + repmat(32:67, ceil(this.n_spe(e) / 12), 1))')';
                    sat = sat(1:n_sat * 3);
                    all_sat = [all_sat sat]; %#ok<AGROW>
                end
                all_sat = reshape(all_sat, 3, numel(all_sat)/3)';
                all_sat(all_sat(:,1) == 32) = this.rinex_ss;
                all_sat(all_sat == 32) = '0'; % sscanf seems to misbehave with spaces
                gps_prn = unique(sscanf(all_sat(all_sat(:,1) == 'G', 2 : 3)', '%2d'));
                glo_prn = unique(sscanf(all_sat(all_sat(:,1) == 'R', 2 : 3)', '%2d'));
                gal_prn = unique(sscanf(all_sat(all_sat(:,1) == 'E', 2 : 3)', '%2d'));
                qzs_prn = unique(sscanf(all_sat(all_sat(:,1) == 'J', 2 : 3)', '%2d'));
                bds_prn = unique(sscanf(all_sat(all_sat(:,1) == 'C', 2 : 3)', '%2d'));
                irn_prn = unique(sscanf(all_sat(all_sat(:,1) == 'I', 2 : 3)', '%2d'));
                sbs_prn = unique(sscanf(all_sat(all_sat(:,1) == 'S', 2 : 3)', '%2d'));
                prn = struct('G', gps_prn', 'R', glo_prn', 'E', gal_prn', 'J', qzs_prn', 'C', bds_prn', 'I', irn_prn', 'S', sbs_prn');
                
                % update the maximum number of rows to store
                n_obs = this.cc.gps.isActive * numel(prn.G) * numel(this.rin_obs_code.G) / 3 + ...
                    this.cc.glo.isActive * numel(prn.R) * numel(this.rin_obs_code.R) / 3 + ...
                    this.cc.gal.isActive * numel(prn.E) * numel(this.rin_obs_code.E) / 3 + ...
                    this.cc.qzs.isActive * numel(prn.J) * numel(this.rin_obs_code.J) / 3 + ...
                    this.cc.bds.isActive * numel(prn.C) * numel(this.rin_obs_code.C) / 3 + ...
                    this.cc.irn.isActive * numel(prn.I) * numel(this.rin_obs_code.I) / 3 + ...
                    this.cc.sbs.isActive * numel(prn.S) * numel(this.rin_obs_code.S) / 3;
                
                clear gps_prn glo_prn gal_prn qzs_prn bds_prn irn_prn sbs_prn;
                
                % order of storage
                % sat_system / obs_code / satellite
                sys_c = char(this.cc.sys_c);
                n_ss = numel(sys_c); % number of satellite system
                
                this.obs_code = [];
                this.prn = [];
                this.system = [];
                this.f_id = [];
                this.wl = [];
                ss_id = find(this.cc.getActive);
                for  s = 1 : n_ss
                    sys = sys_c(s);
                    n_sat = numel(prn.(sys)); % number of satellite system
                    this.n_sat = this.n_sat + n_sat;
                    n_code = numel(this.rin_obs_code.(sys)) / 3; % number of satellite system
                    % transform in n_code x 3
                    obs_code = reshape(this.rin_obs_code.(sys), 3, n_code)';
                    % replicate obs_code for n_sat
                    obs_code = serialize(repmat(obs_code, 1, n_sat)');
                    obs_code = reshape(obs_code, 3, numel(obs_code) / 3)';
                    
                    this.obs_code = [this.obs_code; obs_code];
                    prn_ss = repmat(prn.(sys)', n_code, 1);
                    this.prn = [this.prn; prn_ss];
                    this.system = [this.system repmat(sys, 1, size(obs_code, 1))];
                    
                    f_id = obs_code(:,2);
                    ss = this.cc.(char(this.cc.SYS_NAME{ss_id(s)} + 32));
                    [~, f_id] = ismember(f_id, ss.CODE_RIN3_2BAND);
                    
                    ismember(this.system, this.cc.SYS_C);
                    this.f_id = [this.f_id; f_id];
                    
                    if ss_id(s) == 2 % glonass FDMA system
                        wl = ss.L_VEC((max(1, f_id) - 1) * size(ss.L_VEC, 1) + ss.PRN2IDCH(min(prn_ss, ss.N_SAT))');
                        wl(prn_ss > ss.N_SAT) = NaN;
                        wl(f_id == 0) = NaN;
                    else
                        wl = ss.L_VEC(max(1, f_id))';
                        wl(f_id == 0) = NaN;
                    end
                    this.wl = [this.wl; wl];
                end
                
                this.w_bar.createNewBar(' Parsing epochs...');
                this.w_bar.setBarLen(n_epo);
                
                n_ops = numel(this.rin_obs_code.G)/3; % number of observations per satellite
                n_lps = ceil(n_ops / 5); % number of observation lines per satellite
                
                mask = repmat('         0.00000',1 ,40);
                data_pos = repmat(logical([true(1, 14) false(1, 2)]),1 ,40);
                id_line  = reshape(1 : numel(mask), 80, numel(mask)/80);
                bad_epochs = [];
                
                % init datasets
                obs = zeros(n_obs, n_epo);
                
                for e = 1 : n_epo % for each epoch
                    n_sat = this.n_spe(e);
                    % get the list of satellites in view
                    nlps = ceil(this.n_spe(e) / 12); % number of lines used to store satellite names
                    id_sat = serialize((lim(t_line(e),1) + repmat((0 : nlps - 1)' * (69 + has_cr), 1, 36) + repmat(32:67, nlps, 1))');                    
                    sat = txt(id_sat(1 : n_sat * 3));
                    sat = sat(1:n_sat * 3);
                    sat = reshape(sat, 3, n_sat)';
                    sat(sat(:,1) == 32) = this.rinex_ss;
                    sat(sat == 32) = '0';  % sscanf seems to misbehave with spaces
                    prn_e = sscanf(serialize(sat(:,2:3)'), '%02d');
                    if numel(prn_e) < this.n_spe(e)
                        bad_epochs = [bad_epochs; e];
                        cm = this.log.getColorMode();
                        this.log.setColorMode(false); % disable color mode for speed up
                        this.log.addWarning(sprintf('Problematic epoch found at %s\nInspect the files to detect what went wrong!\nSkipping and continue the parsing, no action taken%s', this.time.getEpoch(e).toString, char(32*ones(this.w_bar.getBarLen(),1))));
                        this.log.setColorMode(cm);
                    else
                        for s = 1 : size(sat, 1)
                            % line to fill with the current observation line
                            obs_line = find((this.prn == prn_e(s)) & this.system' == sat(s, 1));
                            % if is empty I'm reading a constellation that is not active in the constellation collector
                            %   -> discard the unwanted satellite
                            if ~isempty(obs_line)
                                line_start = t_line(e) + ceil(n_sat / 12) + (s-1) * n_lps;
                                line = mask(1 : n_ops * 16);
                                for i = 0 : n_lps - 1
                                    try
                                        line(id_line(1:lim(line_start + i, 3),i+1)) = txt(lim(line_start + i, 1) : lim(line_start + i, 2)-1);
                                    catch
                                        % empty last lines
                                    end
                                end
                                % remove return characters
                                ck = line == ' '; line(ck) = mask(ck); % fill empty fields -> otherwise textscan ignore the empty fields
                                % try with sscanf
                                line = line(data_pos(1 : numel(line)));
                                data = sscanf(reshape(line, 14, numel(line) / 14), '%f');
                                obs(obs_line, e) = data;
                                % alternative approach with textscan
                                %data = textscan(line, '%14.3f%1d%1d');
                                %obs(obs_line(1:numel(data{1})), e) = data{1};
                            end
                        end
                    end
                    this.w_bar.go(e);
                end
                obs(:, bad_epochs) = [];
                this.time.remEpoch(bad_epochs);
            else
                % init datasets
                obs = [];
            end
            this.log.newLine();
            this.obs = obs;
        end
        
        function parseRin3Data(this, txt, lim, eoh, t_start, t_stop, rate)
            if nargin < 6
                t_start = GPS_Time(0);
                t_stop = GPS_Time(800000); % 2190/04/28 an epoch very far away
            end
            if nargin < 7
                rate = [];
            end
            
            % find all the observation lines
            t_line = find([false(eoh, 1); (txt(lim(eoh+1:end,1)) == '>' & txt(lim(eoh+1:end,1)+31) ~= '4' & txt(lim(eoh+1:end,1)+31) ~= '3' )']);
            n_epo = numel(t_line);
            % extract all the epoch lines
            string_time = txt(repmat(lim(t_line,1),1,27) + repmat(2:28, n_epo, 1))';
            % convert the times into a 6 col time
            date = cell2mat(textscan(string_time,'%4f %2f %2f %2f %2f %10.7f'));
            % import it as a GPS_Time obj
            this.time = GPS_Time(date, [], this.file.first_epoch.is_gps);
            to_keep_ep = this.time > t_start & this.time < t_stop;
            this.time.remEpoch(~to_keep_ep);
            t_line(~to_keep_ep) = [];
            if ~isempty(t_line) && ~isempty(rate)
                nominal = this.getNominalTime();
                nominal_ss = this.time.getNominalTime(rate, true);
                to_discard = true(this.time.length, 1);
                % Find the valid epoch that are close to the nominal at the requested rate (aka do not read the entire file)
                t_rel = nominal.getRefTime(floor(nominal.first.getMatlabTime));
                t_rel_ss = nominal_ss.getRefTime(floor(nominal.first.getMatlabTime));
                [~, to_keep_ep] = intersect(round(t_rel * 1e5), round(t_rel_ss * 1e5));
                to_discard(to_keep_ep) = false;
                this.time.remEpoch(to_discard);
                t_line(to_discard) = [];
            end
            ljmp = ([true; diff(this.time.getRefTime) > 1e-7]); % find when epochs change (if the distance between two consecutive epochs is < 1e-7 consider them as duplicate epochs)
            tid = cumsum(ljmp); % time id -> in presence of duplicate epochs tid doesn't change
            this.time.remEpoch(~ljmp); % remove duplicate epochs
            if ~isempty(t_line)
                this.rate = this.time.getRate();
                n_epo = numel(t_line);
                n_true_epo = tid(end);
                
                % get number of observations per epoch
                this.n_spe = sscanf(txt(repmat(lim(t_line,1),1,3) + repmat(32:34, n_epo, 1))', '%d');
                
                % find data lines
                d_line = find(~[true(eoh, 1); (txt(lim(eoh+1:end,1)) == '>')']);
                
                %all_sat = txt(repmat(lim(d_line,1), 1, 3) + repmat(0 : 2, numel(d_line), 1));
                
                % find the data present into the file
                gps_line = d_line(txt(lim(d_line,1)) == 'G');
                glo_line = d_line(txt(lim(d_line,1)) == 'R');
                gal_line = d_line(txt(lim(d_line,1)) == 'E');
                qzs_line = d_line(txt(lim(d_line,1)) == 'J');
                bds_line = d_line(txt(lim(d_line,1)) == 'C');
                irn_line = d_line(txt(lim(d_line,1)) == 'I');
                sbs_line = d_line(txt(lim(d_line,1)) == 'S');
                % Activate only the constellation that are present in the receiver
                %this.cc.setActive([isempty(gps_line) isempty(glo_line) isempty(gal_line) isempty(qzs_line) isempty(bds_line) isempty(irn_line) isempty(sbs_line)]);
                all_const_line = [gps_line; glo_line; gal_line; qzs_line; bds_line; irn_line; sbs_line];
                first_line_space  = txt(lim(all_const_line,1)+1)' == ' ';
                txt(repmat(lim(all_const_line(first_line_space),1), 1, 2)+1) = '0';
                gps_prn = unique(sscanf(txt(repmat(lim(gps_line,1), 1, 2) + repmat(1 : 2, numel(gps_line), 1))', '%2d'));
                glo_prn = unique(sscanf(txt(repmat(lim(glo_line,1), 1, 2) + repmat(1 : 2, numel(glo_line), 1))', '%2d'));
                gal_prn = unique(sscanf(txt(repmat(lim(gal_line,1), 1, 2) + repmat(1 : 2, numel(gal_line), 1))', '%2d'));
                qzs_prn = unique(sscanf(txt(repmat(lim(qzs_line,1), 1, 2) + repmat(1 : 2, numel(qzs_line), 1))', '%2d'));
                bds_prn = unique(sscanf(txt(repmat(lim(bds_line,1), 1, 2) + repmat(1 : 2, numel(bds_line), 1))', '%2d'));
                irn_prn = unique(sscanf(txt(repmat(lim(irn_line,1), 1, 2) + repmat(1 : 2, numel(irn_line), 1))', '%2d'));
                sbs_prn = unique(sscanf(txt(repmat(lim(sbs_line,1), 1, 2) + repmat(1 : 2, numel(sbs_line), 1))', '%2d'));
                
                gps_prn(gps_prn > this.cc.gps.N_SAT(1)) = [];
                glo_prn(glo_prn > this.cc.glo.N_SAT(1)) = [];
                gal_prn(gal_prn > this.cc.gal.N_SAT(1)) = [];
                qzs_prn(qzs_prn > this.cc.qzs.N_SAT(1)) = [];
                bds_prn(bds_prn > this.cc.bds.N_SAT(1)) = [];
                irn_prn(irn_prn > this.cc.irn.N_SAT(1)) = [];
                sbs_prn(sbs_prn > this.cc.sbs.N_SAT(1)) = [];
                
                prn = struct('G', gps_prn', 'R', glo_prn', 'E', gal_prn', 'J', qzs_prn', 'C', bds_prn', 'I', irn_prn', 'S', sbs_prn');
                
                % update the maximum number of rows to store
                n_obs = this.cc.gps.isActive * numel(prn.G) * numel(this.rin_obs_code.G) / 3 + ...
                    this.cc.glo.isActive * numel(prn.R) * numel(this.rin_obs_code.R) / 3 + ...
                    this.cc.gal.isActive * numel(prn.E) * numel(this.rin_obs_code.E) / 3 + ...
                    this.cc.qzs.isActive * numel(prn.J) * numel(this.rin_obs_code.J) / 3 + ...
                    this.cc.bds.isActive * numel(prn.C) * numel(this.rin_obs_code.C) / 3 + ...
                    this.cc.irn.isActive * numel(prn.I) * numel(this.rin_obs_code.I) / 3 + ...
                    this.cc.sbs.isActive * numel(prn.S) * numel(this.rin_obs_code.S) / 3;
                
                clear gps_prn glo_prn gal_prn qzs_prn bds_prn irn_prn sbs_prn;
                
                % order of storage
                % sat_system / obs_code / satellite
                sys_c = char(this.cc.sys_c);
                n_ss = numel(sys_c); % number of satellite system
                
                % init datasets
                obs = zeros(n_obs, n_true_epo);
                
                this.obs_code = [];
                this.prn = [];
                this.system = [];
                this.f_id = [];
                this.wl = [];
                this.n_sat = 0;
                for  s = 1 : n_ss
                    sys = sys_c(s);
                    n_sat = numel(prn.(sys)); % number of satellite system
                    
                    n_code = numel(this.rin_obs_code.(sys)) / 3; % number of satellite system
                    % transform in n_code x 3
                    obs_code = reshape(this.rin_obs_code.(sys), 3, n_code)';
                    % replicate obs_code for n_sat
                    obs_code = serialize(repmat(obs_code, 1, n_sat)');
                    obs_code = reshape(obs_code, 3, numel(obs_code) / 3)';
                    
                    
                    prn_ss = repmat(prn.(sys)', n_code, 1);
                    % discarding satellites whose number exceed the maximum ones for constellations e.g. spare satellites GLONASS
                    this.prn = [this.prn; prn_ss];
                    this.obs_code = [this.obs_code; obs_code];
                    this.n_sat = this.n_sat + n_sat;
                    this.system = [this.system repmat(sys, 1, size(obs_code, 1))];
                    
                    f_id = obs_code(:,2);
                    ss = this.cc.getSys(sys);
                    [~, f_id] = ismember(f_id, ss.CODE_RIN3_2BAND);
                    
                    ismember(this.system, this.cc.SYS_C);
                    this.f_id = [this.f_id; f_id];
                    
                    if sys == 'R'
                        wl = ss.L_VEC((max(1, f_id) - 1) * size(ss.L_VEC, 1) + ss.PRN2IDCH(min(prn_ss, ss.N_SAT))');
                        wl(prn_ss > ss.N_SAT) = NaN;
                        wl(f_id == 0) = NaN;
                    else
                        wl = ss.L_VEC(max(1, f_id))';
                        wl(f_id == 0) = NaN;
                    end
                    if sum(f_id == 0)
                        [~, id] = unique(double(obs_code(f_id == 0, :)) * [1 10 100]');
                        this.log.addWarning(sprintf('These codes for the %s are not recognized, ignoring data: %s', ss.SYS_EXT_NAME, sprintf('%c%c%c ', obs_code(id, :)')));
                    end
                    this.wl = [this.wl; wl];
                end
                
                this.w_bar.createNewBar(' Parsing epochs...');
                this.w_bar.setBarLen(n_epo);
                
                mask = repmat('         0.00000',1 ,60);
                data_pos = repmat(logical([true(1, 14) false(1, 2)]),1 ,60);
                for e = 1 : n_epo % for each epoch
                    sat = txt(repmat(lim(t_line(e) + 1 : t_line(e) + this.n_spe(e),1),1,3) + repmat(0:2, this.n_spe(e), 1));
                    prn_e = sscanf(serialize(sat(:,2:3)'), '%02d');
                    for s = 1 : size(sat, 1)
                        % line to fill with the current observation line
                        obs_line = find((this.prn == prn_e(s)) & this.system' == sat(s, 1));
                        if ~isempty(obs_line)
                            line = txt(lim(t_line(e) + s, 1) + 3 : lim(t_line(e) + s, 2));
                            ck = line == ' ';
                            line(ck) = mask(ck); % fill empty fields -> otherwise textscan ignore the empty fields
                            % try with sscanf
                            line = line(data_pos(1 : numel(line)));
                            data = sscanf(reshape(line, 14, numel(line) / 14), '%f');
                            obs(obs_line(1:size(data,1)), tid(e)) = data;
                        end
                        % alternative approach with textscan
                        %data = textscan(line, '%14.3f%1d%1d');
                        %obs(obs_line(1:numel(data{1})), e) = data{1};
                    end
                    this.w_bar.go(e);
                end
                
                if n_epo > n_true_epo
                    % in case of duplicate epochs cumulate the observations
                    tmp = zeros(n_true_epo, 1);
                    for i = 1 : n_epo
                        tmp(tid(i)) = tmp(tid(i)) + this.n_spe(i);
                    end
                    this.n_spe = tmp;
                end
            else
                % init datasets
                obs = [];
            end
            this.log.newLine();
            this.obs = obs;
        end
    end
    % ==================================================================================================================================================
    %% METHODS GETTER - TIME
    % ==================================================================================================================================================
    
    methods
        % time
        function time = getPositionTime(this)
            % return the time of the computed positions
            %
            % OUTPUT
            %   time     GPS_Time
            %
            % SYNTAX
            %   xyz = this.getPositionTime()
            if this.isStatic()
                time = this.state.getSessionCentralTime();
            else
                time = this.getTime.getCopy();
            end
        end
        
        % standard utility
        function toString(this)
            % Display on screen information about the receiver
            % SYNTAX this.toString();
            if ~this.isEmpty
                fprintf('----------------------------------------------------------------------------------\n')
                this.log.addMarkedMessage(sprintf('Receiver Work Space %s', this.parent.getMarkerName()));
                fprintf('----------------------------------------------------------------------------------\n')
                this.log.addMessage(sprintf(' From     %s', this.time.first.toString()));
                this.log.addMessage(sprintf(' to       %s', this.time.last.toString()));
                this.log.newLine();
                this.log.addMessage(sprintf(' Rate of the observations [s]:            %d', this.getRate()));
                this.log.newLine();
                this.log.addMessage(sprintf(' Maximum number of satellites seen:       %d', max(this.n_sat)));
                this.log.addMessage(sprintf(' Number of stored frequencies:            %d', this.n_freq));
                this.log.newLine();
                this.log.addMessage(sprintf(' Satellite System(s) seen:                "%s"', unique(this.system)));
                this.log.newLine();
                
                xyz0 = this.getAPrioriPos();
                [enu0(1), enu0(2), enu0(3)] = cart2plan(xyz0(:,1), xyz0(:,2), xyz0(:,3));
                static_dynamic = {'Dynamic', 'Static'};
                this.log.addMessage(sprintf(' %s receiver', static_dynamic{this.parent.static + 1}));
                fprintf(' ----------------------------------------------------------\n')
                this.log.addMessage(' Receiver a-priori position:');
                this.log.addMessage(sprintf('     X = %+16.4f m        E = %+16.4f m\n     Y = %+16.4f m        N = %+16.4f m\n     Z = %+16.4f m        U = %+16.4f m', ...
                    xyz0(1), enu0(1), xyz0(2), enu0(2), xyz0(3), enu0(3)));
                
                if ~isempty(this.xyz)
                    enu = zero2nan(this.xyz); [enu(:, 1), enu(:, 2), enu(:, 3)] = cart2plan(zero2nan(this.xyz(:,1)), zero2nan(this.xyz(:,2)), zero2nan(this.xyz(:,3)));
                    xyz_m = median(zero2nan(this.xyz), 1, 'omitnan');
                    enu_m = median(enu, 1, 'omitnan');
                    this.log.newLine();
                    this.log.addMessage(' Receiver median position:');
                    this.log.addMessage(sprintf('     X = %+16.4f m        E = %+16.4f m\n     Y = %+16.4f m        N = %+16.4f m\n     Z = %+16.4f m        U = %+16.4f m', ...
                        xyz_m(1), enu_m(1), xyz_m(2), enu_m(2), xyz_m(3), enu_m(3)));
                    
                    enu = zero2nan(this.xyz); [enu(:, 1), enu(:, 2), enu(:, 3)] = cart2plan(zero2nan(this.xyz(:,1)), zero2nan(this.xyz(:,2)), zero2nan(this.xyz(:,3)));
                    xyz_m = median(zero2nan(this.xyz), 1, 'omitnan');
                    enu_m = median(enu, 1, 'omitnan');
                    this.log.newLine();
                    this.log.addMessage(' Correction of the a-priori position:');
                    this.log.addMessage(sprintf('     X = %+16.4f m        E = %+16.4f m\n     Y = %+16.4f m        N = %+16.4f m\n     Z = %+16.4f m        U = %+16.4f m', ...
                        xyz0(1) - xyz_m(1), enu0(1) - enu_m(1), xyz0(2) - xyz_m(2), enu0(2) - enu_m(2), xyz0(3) - xyz_m(3), enu0(3) - enu_m(3)));
                    this.log.newLine();
                    this.log.addMessage(sprintf('     3D distance = %+16.4f m', sqrt(sum((xyz_m - xyz0).^2))));
                end
                fprintf(' ----------------------------------------------------------\n')
                this.log.addMessage(' Processing statistics:');
                if not(isempty(this.quality_info.s0_ip) || this.quality_info.s0_ip == 0)
                    this.log.addMessage(sprintf('     sigma0 code positioning = %+16.4f m', this.quality_info.s0_ip));
                end
                if not(isempty(this.quality_info.s0) || this.quality_info.s0 == 0)
                    this.log.addMessage(sprintf('     sigma0 PPP positioning  = %+16.4f m', this.quality_info.s0));
                end
                fprintf(' ----------------------------------------------------------\n')
            end
        end
        
        function is_fixed = isFixed(this)
            is_fixed = this.rf.isFixed(this.parent.getMarkerName4Ch);
        end
        
        function is_fixed = hasGoodApriori(this)
            % this is meant to skip any positionin based on code and estimate the postionon only in PPP or network phase adjutsment
            is_fixed = this.rf.hasGoodAPriori(this.parent.getMarkerName4Ch);
        end
        
        function has_apr = hasAPriori(this)
            has_apr = this.rf.hasAPriori(this.parent.getMarkerName4Ch);
        end
        
        function n_obs = getNumObservables(this)
            % get the number of observables stored in the object
            % SYNTAX n_obs = this.getNumObservables()
            n_obs = size(this.obs, 1);
        end
        
        function n_pr = getNumPrEpochs(this)
            % get the number of epochs stored in the object
            % SYNTAX n_pr = this.getNumPrEpochs()
            n_pr = sum(this.obs_code(:,1) == 'C');
        end
        
        function n_pr = getNumPhEpochs(this)
            % get the number of epochs stored in the object
            % SYNTAX n_pr = this.getNumPhEpochs()
            n_pr = sum(this.obs_code(:,1) == 'L');
        end
        
        function n_sat = getNumSat(this, sys_c)
            % get the number of satellites stored in the object
            %
            % SYNTAX
            %   n_sat = getNumSat(<sys_c>)
            if nargin == 2
                n_sat = numel(unique(this.go_id( (this.system == sys_c)' & (this.obs_code(:,1) == 'C' | this.obs_code(:,1) == 'L') )));
            else
                n_sat = numel(unique(this.go_id(this.obs_code(:,1) == 'C' | this.obs_code(:,1) == 'L')));
            end
        end
        
        function n_sat = getMaxSat(sta_list, sys_c)
            % get the number of satellites stored in the object
            %
            % SYNTAX
            %   n_sat = getNumSat(<sys_c>)
            n_sat = zeros(size(sta_list));
            
            for r = 1 : size(sta_list, 2)
                rec = sta_list(~sta_list(r).isEmpty, r);
                
                if ~isempty(rec)
                    if nargin == 2
                        n_sat(r) = max(rec.go_id( (rec.system == sys_c)' & (rec.obs_code(:,1) == 'C' | rec.obs_code(:,1) == 'L') ));
                    else
                        if isempty(rec.go_id)
                            n_sat(r) = 0;
                        else
                            n_sat(r) = max(rec.go_id(rec.obs_code(:,1) == 'C' | rec.obs_code(:,1) == 'L'));
                        end
                    end
                end
            end
        end
        
        function sys_c = getAvailableSys(this)
            % get the available system stored into the object
            % SYNTAX sys_c = this.getAvailableSys()
            
            % Select only the systems present in the file
            sys_c = unique(this.system);
        end
        
        function sys_c = getActiveSys(this)
            % get the active system stored into the object
            % SYNTAX sys_c = this.getActiveSys()
            
            % Select only the systems still present in the file
            go_id = this.getActiveGoIds();
            sys_c = serialize(unique(this.getSysPrn(go_id)))';
        end
        
        function go_id = getActiveGoIds(this)
            % return go_id present in the receiver of the active constellations
            % SYNTAX go_id = this.getActiveGoIds()
            go_id = unique(this.go_id(regexp(this.system, ['[' this.cc.sys_c ']?'])));
        end
        
        function go_id = getGoId(this, sys, prn)
            % return go_id for a given system and prn
            % SYNTAX go_id = this.getGoId(sys, prn)
            go_id = zeros(size(prn));
            if length(sys) == 1
                sys = repmat(sys,length(prn),1);
            end
            for i = 1 : length(prn)
                p = prn(i);
                s = sys(i);
                id = find((this.system == s)' & (this.prn == p), 1, 'first');
                if isempty(id)
                    go_id(i) = 0;
                else
                    go_id(i) = this.go_id(id);
                end
            end
        end
        
        function ant_id = getAntennaId(this, go_id)
            % return ant id given a go_id
            % SYNTAX ant_id = this.getAntennaId(go_id)
            [sys_c, prn] = this.getSysPrn(go_id);
            ant_id = reshape(sprintf('%c%02d', serialize([sys_c; prn]))',3, numel(go_id))';
        end
        
        function dt = getDt(this)
            if numel(this.dt) < max(this.id_sync)
                dt = nan(numel(this.id_sync), 1);
            else
                dt =  this.dt(this.id_sync);
            end
        end
        
        
        function res = getResidual(this)
            if size(this.sat.res,1) < max(this.id_sync)
                res = nan(numel(this.id_sync), this.cc.getMaxNumSat());
            else
                res =  this.sat.res(this.id_sync,:);
            end
        end
        
        function dt_ip = getDtIp(this)
            if numel(this.dt_ip) < max(this.id_sync)
                dt_ip = nan(numel(this.id_sync), 1);
            else
                dt_ip = this.dt_ip(this.id_sync);
            end
        end
        
        function dt_pr = getDtPr(this)
            if numel(this.dt_pr) >= max(this.id_sync)
                dt_pr = this.dt_pr(this.id_sync);
            else
                dt_pr = this.dt_pr(1) * ones(size(this.id_sync));
            end
        end
        
        function dt_ph = getDtPh(this)
            if numel(this.dt_ph) >= max(this.id_sync)
                dt_ph = this.dt_ph(this.id_sync);
            else
                dt_ph = this.dt_ph(1) * ones(size(this.id_sync));
            end
        end
        
        function dt_pp = getDtPrePro(this)
            if numel(this.dt_ip) < max(this.id_sync)
                dt_pp = nan(numel(this.id_sync), 1);
            else
                dt_pp = this.dt_ip(this.id_sync);
            end
        end
        
        function desync = getDesync(this)
            if numel(this.dt_pr) < max(this.id_sync)
                desync = nan(numel(this.id_sync), 1);
            else
                desync = this.desync(this.id_sync);
            end
        end
        
        function amb_mat = getAmbMat(this)
            % gte the ambiguity matrix
            %
            % SYNTAX:
            % amb_mat = this.getAmbMat()
            if ~isempty(this.sat.amb_mat)
                ph = this.getPhases();
                this.sat.amb_mat = zeros(size(this.sat.amb_mat));
            end
            amb_mat = this.sat.amb_mat;
            
        end
        
        function time = getTime(this)
            % return the time stored in the object
            %
            % OUTPUT
            %   time     GPS_Time
            %
            % SYNTAX
            %   xyz = this.getTime()
            %if ~isempty(this(1).id_sync)
            time = this(1).time.getEpoch(this(1).id_sync);
            %else
            %    time = this(1).time.getCopy();
            %end
        end
        
        function missing_epochs = getMissingEpochs(this)
            % return a logical array of missing (code) epochs
            %
            % SYNTAX
            %   missing_epochs = this.getMissingEpochs()
            %
            missing_epochs = all(isnan(this.getPseudoRanges)')';
        end
        
        function xyz = getAPrioriPos_mr(this)
            % return apriori position
            %
            % SYNTAX
            %   xyz = this.getAPrioriPos_mr()
            xyz = this.getAPrioriPos();
        end
        
        function [lon, lat, h_ell] = getGeodCoord(this)
            % return geodetic coordinate of the reciever
            %
            % SYNTAX
            %   [lon, lat, h] = this.getGeodCoord()
            if isempty(this.lat) ||  isempty(this.lat) ||  isempty(this.h_ellips) 
                this.updateCoordinates();
            end
            lon = this.lon;
            lat = this.lat;
            h_ell = this.h_ellips;
        end
        
        function xyz = getAPrioriPos(this)
            % return apriori position
            %
            % SYNTAX:
            %   xyz = this.getAPrioriPos()
            xyz = this.xyz_approx;
            xyz = median(xyz, 1);
            if ~any(xyz) && ~isempty(this.xyz)
                xyz = median(this.getPosXYZ, 1);
            end
        end
        
        % frequencies
        
        function is_mf = isMultiFreq(this)
            % check if receiver has multiple frequencies
            %
            % SYNTAX:
            %     is_mf = isMultiFreq(this)
            is_mf = false;
            for i = 1 : this.parent.cc.getMaxNumSat()
                cur_sat_id = find(this.go_id == i, 1, 'first');
                if not(isempty(cur_sat_id))
                    sat_idx = this.findObservableByFlag('C',i);
                    sat_idx = sat_idx(this.active_ids(sat_idx));
                    if ~isempty(sat_idx)
                        % get epoch for which iono free is possible
                        freq = str2num(this.obs_code(sat_idx,2)); %#ok<ST2NM>
                        u_freq = unique(freq);
                        if length(u_freq)>1
                            is_mf = true;
                            return
                        end
                    end
                end
            end
        end
        
        function freqs = getFreqs(this, sys)
            % get presnt frequencies for system
            idx = this.system == sys;
            freq = str2num(this.obs_code(idx,2)); %#ok<ST2NM>
            freqs = unique(freq);
        end
        
        function err4el = getErr4El(this, err, go_id)
            % compute for each satellite, for each elevation the maximum of err
            % SYNTAX err4el = this.getErr4El(err, <go_id>)
            el_lim = (0 : 1 : 90)';
            n_el = size(el_lim, 1);
            n_sat = size(this.sat.el, 2);
            err4el = zeros(n_sat, n_el - 1);
            
            if nargin == 2
                go_id = (1 : n_sat)';
            end
            
            for s = unique(go_id)'
                for e = 1 : n_el - 1
                    id_el = (this.sat.el(:, s) > el_lim(e)) & (this.sat.el(:, s) <= el_lim(e + 1));
                    if sum(id_el) > 0
                        for id_s = find(go_id == s)'
                            err4el(s, e) = max([err4el(s, e); nan2zero(err(id_el, id_s))]);
                        end
                    end
                end
            end
            
            err4el = zero2nan(err4el);
        end
        
        function [nominal_time, nominal_time_ext] = getNominalTime(this, rate, is_ext)
            % get the nominal time aka rounded time cosidering a constant
            % sampling rate
            %
            % OUTPUT
            %   nominal_time        it's the rounded time around rate steps
            %   nominal_time_ext    it's the rounded time with no gaps or duplicates
            %
            % SYNTAX
            %   [nominal_time, nominal_time_ext] = this.getNominalTime(<rate>)
            %   nominal_time                     = this.getNominalTime(<rate>, false (default))
            %   nominal_time_ext                 = this.getNominalTime(<rate>, true)
            
            if nargin < 2 || isempty(rate)
                rate = this.time.getRate;
            end
            if nargin < 3 || isempty(is_ext)
                is_ext = false;
            end
            
            if nargout == 1
                [nominal_time] = this.time.getNominalTime(rate, is_ext);
            else
                [nominal_time, nominal_time_ext] = this.time.getNominalTime(rate, is_ext);
            end
        end
        
        function time_tx = getTimeTx(this, sat)
            % SYNTAX
            %   this.getTimeTx(epoch);
            %
            % INPUT
            % OUTPUT
            %   time_tx = transmission time
            %   time_tx =
            %
            %
            %   Get Transmission time
            idx = this.sat.avail_index(:, sat) > 0;
            time_tx = this.time.getSubSet(idx);
            if isempty(this.sat.tot)
                this.updateAllTOT();
            end
            time_tx.addSeconds( - this.sat.tot(idx, sat));
        end
        
        function time_of_travel = getTOT(this)
            % SYNTAX
            %   this.getTraveltime()
            % INPUT
            % OUTPUT
            %   time_of_travel   = time of travel
            %
            %   Compute the signal transmission time.
            time_of_travel = this.tot;
        end
        
        function dtRel = getRelClkCorr(this, sat)
            %  : get clock offset of the satellite due to
            % special relativity (eccntrcity term)
            idx = this.sat.avail_index(:,sat) > 0;
            [X,V] = this.sat.cs.coordInterpolate(this.time.getSubSet(idx),sat);
            dtRel = -2 * sum(conj(X) .* V, 2) / (Core_Utils.V_LIGHT ^ 2); % Relativity correction (eccentricity velocity term)
        end
        
        function dtS = getDtS(this, sat)
            % SYNTAX
            %   this.getDtS(time_rx)
            %
            % INPUT
            %   time_rx   = reception time
            %
            % OUTPUT
            %   dtS     = satellite clock errors
            %
            %   Compute the satellite clock error.
            if nargin < 2
                dtS = zeros(size(this.sat.avail_index));
                dtS(this.sat.avail_index(:,s),s) = this.sat.cs.clockInterpolate(this.time.getSubSet(this.sat.avail_index(:,s)), 1 : size(dtS,2));
            else
                idx = this.sat.avail_index(:,sat) > 0;
                if sum(idx) > 0
                    dtS = this.sat.cs.clockInterpolate(this.time.getSubSet(idx), sat);
                else
                    dtS = zeros(0,1);
                end
            end
        end
        
        function [XS_tx_r ,XS_tx] = getXSTxRot(this, go_id)
            % SYNTAX
            %   [XS_tx_r ,XS_tx] = this.getXSTxRot( sat)
            %
            % INPUT
            % sat = go-id of the satellite
            % OUTPUT
            % XS_tx = satellite position computed at trasmission time
            % XS_tx_r = Satellite postions at transimission time rotated by earth rotation occured
            % during time of travel
            %
            %   Compute satellite positions at transmission time and rotate them by the earth rotation
            %   occured during time of travel of the signal
            if nargin > 1
                [XS_tx] = this.getXSTx(go_id);
                [XS_tx_r]  = this.earthRotationCorrection(XS_tx, go_id);
            else
                n_sat = this.parent.getMaxSat;
                XS_tx_r = zeros(this.time.length, n_sat, 3);
                for i = unique(this.go_id)'
                    [XS_tx] = this.getXSTx(i);
                    [XS_tx_r_temp]  = this.earthRotationCorrection(XS_tx, i);
                    XS_tx_r(this.sat.avail_index(:,i) ,i ,:) = permute(XS_tx_r_temp, [1 3 2]);
                end
            end
        end
        
        function [XS_loc] = getXSLoc(this, go_id)
            % SYNTAX
            %   [XS_tx_r ,XS_tx] = this.getXSLoc( sat)
            %
            % INPUT
            %   sat = go-id of the satellite
            % OUTPUT
            %   XS_tx = satellite position computed at trasmission time
            %   XS_tx_r = Satellite postions at transimission time rotated by earth rotation occured during time of travel
            %
            %   Compute satellite positions at transmission time and rotate them by the earth rotation
            %   occured during time of travel of the signal and subtract
            %   the postion term
            n_epochs = this.time.length;
            if nargin > 1
                sat_idx = this.sat.avail_index(:, go_id) > 0;
                XS = this.getXSTxRot(go_id);
                XS_loc = nan(n_epochs, 3);
                XS_loc(sat_idx,:) = XS;
                if size(this.xyz,1) == 1
                    XR = repmat(this.xyz, n_epochs, 1);
                else
                    XR = this.xyz;
                end
                XS_loc = XS_loc - XR;
            else
                n_sat = this.parent.cc.getMaxNumSat();
                XS_loc = zeros(n_epochs, n_sat,3);
                for i = unique(this.go_id)'
                    XS_loc(:,i ,:) = this.getXSLoc(i);
                end
            end
        end
        
        function [XS_tx] = getXSTx(this, sat)
            % SYNTAX
            %   [XS_tx_frame , XS_rx_frame] = this.getXSTx()
            %
            % INPUT
            %  obs : [1x n_epochs] pseudi range observations
            %  sta : index of the satellite
            % OUTPUT
            % XS_tx = satellite position computed at trasmission time
            %
            % Compute satellite positions at trasmission time
            time_tx = this.getTimeTx(sat);
            %time_tx.addSeconds(); % rel clok neglegible
            [XS_tx, ~] = this.sat.cs.coordInterpolate(time_tx, sat);
            
            
            %                 [XS_tx(idx,:,:), ~] = this.sat.cs.coordInterpolate(time_tx);
            %             XS_tx  = zeros(size(this.sat.avail_index));
            %             for s = 1 : size(XS_tx)
            %                 idx = this.sat.avail_index(:,s);
            %                 %%% compute staeliite position a t trasmission time
            %                 time_tx = this.time.subset(idx);
            %                 time_tx = time_tx.time_diff - this.sat.tot(idx,s)
            %                 [XS_tx(idx,:,:), ~] = this.sat.cs.coordInterpolate(time_tx);
            %             end
        end
        
        function obs_code = getAvailableCode(this, sys_c)
            % get the available observation code for a specific sys
            % SYNTAX obs_code = this.getAvailableCode(sys_c)
            tmp = this.obs_code(this.system == sys_c, :);
            [~, code_ok] = unique(uint32(tmp * ([1 2^8 2^16]')));
            obs_code = tmp(code_ok, :);
        end
        
        function is_static = isStatic(this)
            % return true if the receiver is static
            % SYNTAX is_static = this.isStatic()
            is_static = this.parent.static;
        end
        
        function is_pp = isPreProcessed(this)
            is_pp = this.pp_status;
        end
        
        function [iono_mf] = getSlantIonoMF(this)
            % Get Iono mapping function for all the valid elevations
            [lat, ~, ~, h_ortho] = this.getMedianPosGeodetic_mr();
            
            atmo = Core.getAtmosphere();
            [iono_mf] = atmo.getIonoMF(lat ./180 * pi, h_ortho, this.getEl ./180 * pi);
        end
        
        function [mfh, mfw] = getSlantMF(this, id_sync)
            % Get Mapping function for the satellite slant
            %
            % OUTPUT
            %   mfh: hydrostatic mapping function
            %   mfw: wet mapping function
            %
            % SYNTAX
            %   [mfh, mfw] = this.getSlantMF()
            
            
            n_sat = this.parent.getMaxSat;
            
            if n_sat == 0
                mfh = [];
                mfw = [];
            else
                mfh = zeros(this.length, n_sat);
                mfw = zeros(this.length, n_sat);
                
                if this.length > 0
                    t = 1;
                    
                    atmo = Core.getAtmosphere();
                    [lat, lon, h_ellipse, h_ortho] = this.getMedianPosGeodetic();
                    lat = median(lat);
                    lon = median(lon);
                    h_ortho = median(h_ortho);
                    if nargin == 1
                        for s = 1 : numel(this)
                            if ~isempty(this(s))
                                if this(s).state.mapping_function == 3
                                    [mfh_tmp, mfw_tmp] = atmo.niell(this(s).time, lat./180*pi, (this(s).sat.el)./180*pi,h_ellipse);
                                elseif this(s).state.mapping_function == 2
                                    [mfh_tmp, mfw_tmp] = atmo.vmf_grd(this(s).time, lat./180*pi, lon./180*pi, (this(s).sat.el)./180*pi,h_ellipse);
                                elseif this(s).state.mapping_function == 1
                                    [mfh_tmp, mfw_tmp] = atmo.gmf(this(s).time, lat./180*pi, lon./180*pi, h_ortho, (this(s).sat.el)./180*pi);
                                end
                                
                                if isempty(this(s).id_sync)
                                    mfh(t : t + this(s).length - 1, 1 : size(this(s).sat.el, 2)) = mfh_tmp;
                                    mfw(t : t + this(s).length - 1, 1 : size(this(s).sat.el, 2)) = mfw_tmp;
                                else
                                    mfh(t : t + this(s).length - 1, 1 : size(this(s).sat.el, 2)) = mfh_tmp(this(s).id_sync, :);
                                    mfw(t : t + this(s).length - 1, 1 : size(this(s).sat.el, 2)) = mfw_tmp(this(s).id_sync, :);
                                end
                                t = t + this(s).length;
                            end
                        end
                    else
                        if numel(id_sync) > 0
                            for s = 1 : numel(this)
                                if ~isempty(this(s))
                                    if this(s).state.mapping_function == 3
                                        [mfh_tmp, mfw_tmp] = atmo.niell(this(s).time, lat./180*pi, (this(s).sat.el)./180*pi,h_ellipse);
                                    elseif this.state.mapping_function == 2
                                        [mfh_tmp, mfw_tmp] = atmo.vmf_grd(this(s).time, lat./180*pi, lon./180*pi, (this(s).sat.el)./180*pi,h_ellipse);
                                    elseif this.state.mapping_function == 1
                                        [mfh_tmp, mfw_tmp] = atmo.gmf(this(s).time, lat./180*pi, lon./180*pi, h_ortho, (this(s).sat.el)./180*pi);
                                    end
                                    
                                    
                                    mfh(t : t + length(id_sync) - 1, 1 : size(this(s).sat.el, 2)) = mfh_tmp(id_sync, :);
                                    mfw(t : t + length(id_sync) - 1, 1 : size(this(s).sat.el, 2)) = mfw_tmp(id_sync, :);
                                    t = t + this(s).length;
                                end
                            end
                        end
                    end
                end
            end
        end
        
        function [P, T, H] = getPTH(this, use_id_sync)
            % Get Pressure temperature and humidity at the receiver location
            %
            % OUTPUT
            %   P : pressure [hPa] [mbar]
            %   T : celsius degree
            %   H : %
            %
            % SYNTAX
            %   [P, T, H] = getPTH(this,time,flag)
            flag = this.state.meteo_data;
            if nargin < 2
                use_id_sync = false;
            end
            time = this.time;
            l = time.length;
            
            if isempty(this.meteo_data)
                flag = 1;
            end
            switch flag
                case 1 % standard atmosphere
                    atmo = Core.getAtmosphere();
                    this.updateCoordinates();
                    Pr = atmo.STD_PRES;
                    % temperature [K]
                    Tr = atmo.STD_TEMP;
                    % humidity [%]
                    Hr = atmo.STD_HUMI;
                    h = this.h_ortho;
                    if this.isStatic()
                        P = zeros(l,1);
                        T = zeros(l,1);
                        H = zeros(l,1);
                        P(:) = Pr * (1-0.0000226*h).^5.225;
                        T(:) = Tr - 0.0065*h;
                        H(:) = Hr * exp(-0.0006396*h);
                    else
                        P = Pr * (1-0.0000226*h).^5.225;
                        T = Tr - 0.0065*h;
                        H = Hr * exp(-0.0006396*h);
                    end
                case 2 % gpt
                    atmo = Core.getAtmosphere();
                    this.updateCoordinates();
                    time = time.getGpsTime();
                    if this.isStatic()
                        [P, T, undu] = atmo.gpt( time, this.lat/180*pi, this.lon/180*pi, this.h_ellips, this.h_ellips - this.h_ortho);
                        H = zeros(l,1);
                        H(:) = atmo.STD_HUMI;% * exp(-0.0006396*this.h_ortho);
                    else
                        P = zeros(l,1);
                        T = zeros(l,1);
                        for i = 1 : l
                            [P(l), T(l), undu] = atmo.gpt( time(l), this.lat(min(l, numel(this.lat)))/180*pi, this.lon(min(l, numel(this.lat)))/180*pi, this.h_ellips(min(l, numel(this.lat))), this.h_ellips(min(l, numel(this.lat))) - this.h_ortho(min(l, numel(this.lat))));
                        end
                        H = atmo.STD_HUMI* exp(-0.0006396*this.h_ortho);
                    end
                case 3 % local meteo data
                    atmo = Core.getAtmosphere();
                    
                    P = this.meteo_data.getPressure(time);
                    T = this.meteo_data.getTemperature(time);
                    H = this.meteo_data.getHumidity(time);
                    
                    if any(isnan(P)) || any(isnan(T))
                        this.updateCoordinates();
                        time = time.getGpsTime();
                        if this.isStatic()
                            [P, T, undu] = atmo.gpt( time, this.lat/180*pi, this.lon/180*pi, this.h_ellips, this.h_ellips - this.h_ortho);
                        else
                            P = zeros(l,1);
                            T = zeros(l,1);
                            for i = 1 : l
                                [P(l), T(l), undu] = atmo.gpt( time(l), this.lat(l)/180*pi, this.lon(l)/180*pi, this.h_ellips(l), this.h_ellips(l) - this.h_ortho(l));
                            end
                        end
                    end
                    
                    if any(isnan(H))
                        % Fall back to std values
                        H(isnan(H)) = atmo.STD_HUMI; % * exp(-0.0006396*this.h_ortho);
                    end
            end
            if use_id_sync
                P = P(this.getIdSync);
                T = T(this.getIdSync);
                H = H(this.getIdSync);
            end
        end
        
        function updateAprTropo(this)
            % update arpiori z tropo delays
            if isempty(this.tge) || all(isnan(this.tge))
                this.tge = zeros(this.length,1);
                this.tgn = zeros(this.length,1);
            end
            if this.state.zd_model == 1 % sastamoinen + met
                [P,T,H] = this.getPTH();
                updateAprZhd(this,P,T,H);
                updateAprZwd(this,P,T,H);
            else
                updateAprZhd(this);
                updateAprZwd(this);
            end
        end
        
        function updateAprZhd(this,P,T,H)
            % update zhd
            this.updateCoordinates()
            switch this.state.zd_model
                case 1 %% saastamoinen
                    if nargin < 2
                        [P, T, H] = this.getPTH();
                    end
                    h = this.h_ortho;
                    lat = this.lat;
                    this.apr_zhd = Atmosphere.saast_dry(P,h,lat);
                case 2 %% vmf gridded
                    atmo = Core.getAtmosphere();
                    this.apr_zhd = atmo.getVmfZhd(this.time.getGpsTime, this.lat, this.lon, this.h_ellips);
            end
            
        end
        
        function updateAprZwd(this,P,T,H)
            %update zwd
            if isempty(this.lat)
                this.updateCoordinates()
            end
            switch this.state.zd_model
                case 1 %% saastamoinen
                    if nargin < 2
                        [P, T, H] = this.getPTH();
                    end
                    h = this.h_ortho;
                    this.apr_zwd = Atmosphere.saast_wet(T,H,h);
                case 2 %% vmf gridded
                    atmo = Core.getAtmosphere();
                    this.apr_zwd = atmo.getVmfZwd(this.time.getGpsTime, this.lat, this.lon, this.h_ellips);
            end
        end
        
        function swtd = getSlantZWD(this, smooth_win_size, id_extract)
            % Get the "zenithalized" wet delay
            % SYNTAX
            %   sztd = this.getSlantZWD(<flag_smooth_data = 0>)
            
            if nargin < 3
                id_extract = 1 : this.getTime.length;
            end
            
            if ~isempty(this(1).zwd)
                [mfh, mfw] = this.getSlantMF();
                swtd = (zero2nan(this.getSlantTD) - bsxfun(@times, mfh, this.getAprZhd)) ./ mfw;
                swtd(swtd <= 0) = nan;
                swtd = swtd(id_extract, :);
                
                if nargin >= 2 && smooth_win_size > 0
                    t = this.getTime.getEpoch(id_extract).getRefTime;
                    for s = 1 : size(swtd,2)
                        id_ok = ~isnan(swtd(:, s));
                        if sum(id_ok) > 3
                            lim = getOutliers(id_ok);
                            lim = limMerge(lim, 2*smooth_win_size);
                            
                            %lim = [lim(1) lim(end)];
                            for l = 1 : size(lim, 1)
                                if (lim(l, 2) - lim(l, 1) + 1) > 3
                                    id_ok = lim(l, 1) : lim(l, 2);
                                    ztd = this.getZwd();
                                    swtd(id_ok, s) = splinerMat(t(id_ok), swtd(id_ok, s) - zero2nan(ztd(id_ok)), smooth_win_size, 0.05) + zero2nan(ztd(id_ok));
                                end
                            end
                        end
                    end
                end
            else
                this.log.addWarning('ZWD and slants have not been computed');
            end
        end
        
        function [pos] = getXR(this)
            % get xyz or the same repeated by the number of epoch
            % SYNTAX [XR] = getXR(this)
            if size(this.xyz, 1) == 1
                pos = repmat(this.xyz,this.time.length, 1);
            else
                pos = this.xyz;
            end
        end
        
        function wl = getWavelength(this, id_ph)
            % get the wavelength of a specific phase observation
            % SYNTAX wl = this.getWavelength(id_ph)
            wl = this.wl(id_ph);
        end
        
        function obs_code = getAvailableObsCode(this, flag, sys_c)
            % Get all the observation codes stored into the receiver
            %
            % SYNTAX
            %   obs_code = this.getAvailableObsCode(flag, sys_c);
            
            if nargin < 3 || isempty(sys_c)
                lid = (1 : numel(this.system))';
            else
                lid = (this.system == sys_c)';
            end
            if nargin < 2 || isempty(flag)
                flag = '???';
            end
            
            obs_code = this.obsNum2Code(unique(this.obsCode2Num(this.obs_code(lid,:))));
            
            flag = [flag '?' * char(ones(1, 3 - size(flag, 1)))];
            
            lid = iif(flag(1) == '?', true(size(obs_code, 1), 1), obs_code(:, 1) == flag(1)) & ...
                iif(flag(2) == '?', true(size(obs_code, 1), 1), obs_code(:, 2) == flag(2)) & ...
                iif(flag(3) == '?', true(size(obs_code, 1), 1), obs_code(:, 3) == flag(3));
            
            obs_code = obs_code(lid, :);
        end
        
        function sys_c = getAvailableSS(this)
            % Get all the available satellite systems
            %
            % SYNTAX
            %   sys_c = getAvailableSS(flag, sys_c);
            
            sys_c = unique(this.system(:))';
        end
        
        function [ph, wl, id_ph] = getPhases(this, sys_c, freq_c)
            % get the phases observations in meter (not cycles)
            % SYNTAX [ph, wl, id_ph] = this.getPhases(<sys_c>, <freq_c>)
            % SEE ALSO: setPhases getPseudoRanges setPseudoRanges
            
            if nargin > 2
                id_ph = this.obs_code(:, 1) == 'L' & this.obs_code(:, 2) == freq_c;
            else
                id_ph = this.obs_code(:, 1) == 'L';
            end
            
            if (nargin == 2) && ~isempty(sys_c)
                id_ph = id_ph & (this.system == sys_c)';
            end
            ph = this.obs(id_ph, :);
            if not(isempty(this.sat.outliers_ph_by_ph))
                if (nargin == 2) && ~isempty(sys_c)
                    ph(this.sat.outliers_ph_by_ph(:,(this.system(id_ph) == sys_c)')') = nan;
                else
                    ph(this.sat.outliers_ph_by_ph') = nan;
                end
            end
            wl = this.wl(id_ph);
            
            ph = bsxfun(@times, zero2nan(ph), wl)';
        end
        
        function [last_repair, old_ph, old_synt] = getLastRepair(this, go_id, band_tracking)
            % Get the last integer (or half cycle) ambiguity repair applyied to the satellite
            %
            % SYNTAX
            %   last_repair = this.getLastRepair(go_id, <band_tracking>)
            %
            % EXAMPLE
            %   last_repair = work.getLastRepair(go_id, '2W')
            old_ph = [];
            old_synt = [];
            last_repair = 0;
            if ~this.isEmpty
                if isempty(this.sat.last_repair)
                    last_repair = zeros(numel(go_id), 1);
                else
                    if nargin > 2 && ~isempty(band_tracking)
                        obs_code = ['L' band_tracking];
                    else
                        obs_code = 'L??';
                    end
                    
                    [sys_c, prn] = this.getSysPrn(go_id);
                    id_obs = this.findObservableByFlag(obs_code, sys_c, prn);
                    if ~isempty(id_obs)
                        last_repair = this.sat.last_repair(id_obs);
                        if nargout >= 2
                            old_ph = this.obs(id_obs, :)';
                        end
                        if nargout > 2
                            id_obs_all = this.findObservableByFlag(obs_code, sys_c);
                            old_synt = this.synt_ph(:, (id_obs_all == id_obs)) ./ this.wl(id_obs);
                        end
                    end
                end
            end
        end
        
        function [pr, id_pr] = getPseudoRanges(this, sys_c)
            % get the pseudo ranges observations in meter (not cycles)
            % SYNTAX [pr, id_pr] = this.getPseudoRanges(<sys_c>)
            % SEE ALSO: getPhases setPhases setPseudoRanges
            
            id_pr = this.obs_code(:, 1) == 'C';
            if (nargin == 2)
                id_pr = id_pr & (this.system == sys_c)';
            end
            pr = zero2nan(this.obs(id_pr, :)');
        end
        
        function [dop, wl, id_dop] = getDoppler(this, sys_c)
            % get the doppler observations
            % SYNTAX [dop, id_dop] = this.getDoppler(<sys_c>)
            % SEE ALSO: setDoppler
            
            id_dop = this.obs_code(:, 1) == 'D';
            if (nargin == 2)
                id_dop = id_dop & (this.system == sys_c)';
            end
            dop = zero2nan(this.obs(id_dop, :)');
            wl = this.wl(id_dop);
            dop = bsxfun(@times, zero2nan(dop), wl');
        end
        
        function [snr, id_snr] = getSNR(this, sys_c, freq_c)
            % get the SNR of the observations
            %
            % SYNTAX
            %   [snr, id_snr] = this.getSNR(<sys_c>)
            if isempty(this.obs_code)
                snr = [];
                id_snr = [];
            else
                if nargin < 3
                    id_snr = this.obs_code(:, 1) == 'S';
                else
                    id_snr = this.obs_code(:, 1) == 'S' & this.obs_code(:, 2) == freq_c;
                end
                if (nargin >= 2) && ~isempty(sys_c)
                    id_snr = id_snr & (this.system == sys_c)';
                end
                snr = zero2nan(this.obs(id_snr, :)');
            end
        end
        
        function [snr_bt, snr_code] = getTrackingSNR(this)
            % Get one single "mean" SNR per tracking/band
            % Defined as a polynomial of degree 2 in sin(el) space
            % Estimated in [0 : 90] degree
            %
            % SYNTAX
            %   [snr_bt, snr_code] = this.getTrackingSNR();
            %
            % EXAMPLE
            %   [snr_bt, snr_code] = rec(1).work.getTrackingSNR();
            %   figure; clf; a=gca; a.ColorOrder = Core_UI.getColor(1 : size(snr_bt,2), size(snr_bt,2)); hold on; plot(0 : 90, snr_bt); legend(snr_code); setAllLinesWidth(2);
            
            i = 0;
            snr_bt = [];
            snr_code = '';
            for sys_c = unique(this.system)
                [snr, id_snr] = this.getSNR(sys_c);
                id_snr = find(id_snr);
                
                el = this.sat.el;
                % Fix ambiguity for the same frequency
                % close all
                go_id_snr = this.go_id(id_snr);
                % calibrate snr
                for b = unique(this.obs_code(id_snr, 2))'
                    idb = find(this.obs_code(id_snr, 2) == b);
                    for t = unique(this.obs_code(id_snr(idb), 3))'
                        i = i + 1;
                        idbt = find(this.obs_code(id_snr(idb), 3) == t);
                        elbt = el(:,this.go_id(id_snr(idb(idbt))));
                        snr_bt_all = snr(:, idb(idbt));
                        id_ok = ~isnan(zero2nan(snr_bt_all));
                        snr_bt(:, i) = Core_Utils.interp1LS([sind(elbt(id_ok)); 2-sind(elbt(id_ok))], [snr_bt_all(id_ok); snr_bt_all(id_ok)], 2, sind(0 : 90));
                        %figure; plot(elbt, zero2nan(ssnr(:, idb(idbt))), '.');
                        %hold on; plot(0:90, snr_bt, 'k.-', 'LineWidth', 2);
                        snr_code(i, :) = [sys_c ' ' b t];
                    end
                end
            end
        end
        
        function [flagged_data] = search4outliers(this, res, level, thr)
            % Analyse phase residuals and get a possible outliers set
            % works on level
            %
            %   level 4-3:    mark very bad observable 0.9% worse among all the residuals greater than 50mm 
            %                 when no oultier are found use a normal threshold automatically computed
            %   level 3-0:    use multiple thresholds considering deviation from "normal" oscillations of the residuals
            %
            % SYNTAX
            %   flagged_data = search4outliers(this, res)
            
            if nargin < 3
                level = 0;
            end
            
            n_sat = size(res, 2);
            % median value above 6 cm
            tmp_ko = (abs(Core_Utils.diffAndPred(nan2zero(movmedian(mean(abs(zero2nan(res * 1e3)), 2, 'omitnan'), 7, 'omitnan')))) > 0.6);

            % remove possible local biases due to bad satellites
            sensor = zero2nan(res * 1e3);            
            starting_bias = nan2zero(median((sensor(1:find(tmp_ko, 1, 'first'), :)), 'omitnan'));
            tmp_jmp = cumsum(nan2zero(Core_Utils.diffAndPred(sensor) .* double(repmat(tmp_ko, 1, n_sat)))) .* ~isnan(zero2nan(sensor)) + repmat(starting_bias, size(sensor, 1), iif(numel(starting_bias) == 1, size(sensor, 2), 1));
            
            if nargin < 4
                % flag outliers above 5cm
                very_ko = sensor >= max(50, perc(abs(sensor(abs(nan2zero(sensor)) > 50)), 0.9));
                if sum(very_ko(:)) == 0
                    std_sensor = [5 2.5] .* max(3, median(std(sensor, 'omitnan'), 'omitnan'));
                else
                    tmp = sensor;
                    tmp(very_ko) = nan;
                    std_sensor = [5 2.5] .* max(3, median(std(tmp, 'omitnan'), 'omitnan'));
                end
            else
                very_ko = 0;
                if numel(thr) == 1
                    std_sensor = [1 0.5] .* thr;
                else
                    std_sensor = thr(1:2);
                end
            end
            % Find outlier and follow the arc
            if  level >= 2
                flagged_data = very_ko;
            else
                flagged_data = this.flagArcOutliers(sensor, std_sensor(1), std_sensor(2));
            end
                        
            if level < 3
                % check for bad std
                % mark sat above a 2 std level (if the std level is greater than 8mm
                id_ko = repmat(std(sensor, 1, 2, 'omitnan'),1, n_sat) > 6 & abs(sensor) > 10; % if the epoch is very bad and the residual is bad itself
                id_ko = id_ko & abs(bsxfun(@minus, sensor, strongMean(sensor, 1, 1, 1))) > max(std_sensor(2), repmat(2*std(sensor,1,2,'omitnan'),1, n_sat));
                if level == 1
                    % mark outliers out of thr level
                    flagged_data = id_ko | this.flagArcOutliers(sensor, this.state.pp_max_phase_err_thr * 1e3, this.state.pp_max_phase_err_thr * 1e3 * 0.8);
                    flagged_data = flagMergeArcs(flagged_data | isnan(sensor), this.state.getMinArc) & ~isnan(sensor); % mark short arcs close to bad observations
                end
                % remove drifting
                tmp_ko = find(tmp_ko);
                if any(tmp_ko)
                    if tmp_ko(end) == size(sensor, 1)
                        tmp_ko(end) = size(sensor, 1) +1;
                    else
                        tmp_ko = [tmp_ko; (size(sensor, 1) +1)];
                    end
                    if tmp_ko(1) ~= 1
                        tmp_ko = [1; tmp_ko];
                    end
                    lim = [tmp_ko(1 : end - 1) (tmp_ko(2 : end) - 1)];
                    
                    for s = 1 : n_sat
                        for l = 2 : size(lim, 1)
                            id = lim(l, 1) : lim(l, 2);
                            med_tmp = median(sensor(id, s), 'omitnan');
                            cur_tmp = mean(tmp_jmp(id, s), 'omitnan');
                            tmp_jmp(id, s) = iif(abs(med_tmp) > abs(cur_tmp), cur_tmp, med_tmp);
                        end
                    end
                end                
                sensor = sensor - tmp_jmp;
                
                % remove slow movements
                for s = 1 : n_sat
                    if any(sensor(:, s))
                        id_ok = find(~isnan(sensor(:,s)));
                        sensor(id_ok, s) = sensor(id_ok, s) - splinerMat(id_ok, sensor(id_ok, s), 300 / this.getRate(), 1e-6);
                    end
                end
                sensor = bsxfun(@minus, sensor, strongMean(zero2nan(sensor)', 0.7, 0.7, 2)');
                threshold = [5 2.5] .* max(2, median(std(sensor, 'omitnan'), 'omitnan'));
                flagged_data = flagged_data | this.flagArcOutliers(sensor, threshold(1), threshold(2));
                %                 %             fh(4) = figure; plot(sensor, '.', 'Color', [0.7 0.7 0.7]); hold on; plot(sensor .* zero2nan(double(flagged_data)), '.', 'MarkerSize', 10); dockAllFigures;
                sensor = sensor + tmp_jmp;
                sensor = bsxfun(@minus, sensor, strongMean(zero2nan(sensor)', 0.7, 0.7, 2)');
                threshold = [5 2.5] .* max(2, median(std(sensor, 'omitnan'), 'omitnan'));
                flagged_data = flagged_data | this.flagArcOutliers(sensor,threshold(1), threshold(2));
            end
            %             fh(1) = figure; plot(sensor, '.-', 'Color', [0.7 0.7 0.7]); hold on; plot(sensor .* zero2nan(double(flagged_data)), '.', 'MarkerSize', 10); dockAllFigures;
            %             fh(2) = figure; plot(res*1e3, '.-'); ax = []; ax(1) = gca;
            %             fh(3) = figure; plot(res*1e3, '.-', 'Color', [0.7 0.7 0.7]); hold on; plot(1e3 * res .* zero2nan(double(flagged_data)), '.-', 'MarkerSize', 10); ax(2) = gca; dockAllFigures;
            %             linkaxes(ax);
            %             pause(1);
            %             close(fh)
            flagged_data = sparse(flagged_data);
        end
        
        function ko_flag = flagArcOutliers(this, data, thr_detect, thr_cut)
            % Flag arcs using a double treshold, first to detect second to enlarge the flagging
            %
            % SYNTAX
            %   ko_flag = this.flagArcOutliers(data, thr_detect, thr_cut)
            n_sat = size(data, 2);
            ko_flag = false(size(data));
            for s = 1 : n_sat
                if any(data(:,s))
                    id_det = find(abs(data(:, s)) > thr_detect);
                    id_cut = flagExpand(abs(data(:, s)) > thr_cut, 3);
                    if any(id_cut)
                        lim = getOutliers(id_cut);
                        lim_ok = true(size(lim, 1), 1);
                        for l = 1 : size(lim, 1)
                            lim_ok(l) = any(ismember(lim(l, 1) : lim(l, 2), id_det));
                        end
                        lim(~lim_ok, :) = [];
                        for l = 1 : size(lim, 1)
                            ko_flag(lim(l, 1) : lim(l, 2), s) = true;
                        end
                    end
                end
            end
        end
        
        function [flattened_data, data_trend, data_jmp] = flattenPhases(this, data_in, cs_size)
            % Returns the input data "flattened"
            % Trend and (integer) jumps are removed
            %
            % SYNTAX:
            %   [flattened_data, data_trend, data_jmp] = flattenPhases(this, data_in)
            %
            % INPUT:
            %   data_in             matrix of values [n_epochs x n_sat]
            %
            % OUTPUT:
            %   flattened_data      data used for data repair as flattened as possible
            %   data_trend          satellite by satellite trend
            %   data_jmp            ambiguity repair
            
            if nargin < 3
                cs_size = this.state.getCycleSlipThr();
            end
            rate = this.getRate();
            
            flattened_data = strongDeTrend(data_in);
            data_trend = data_in - flattened_data;
            
            % remove trends
            % remove clock
            % fill nan with the last valid value
            sensor = simpleFill1D(flattened_data, isnan(flattened_data), 'last');
            sensor = Core_Utils.diffAndPred(sensor);
            sensor = bsxfun(@minus, sensor, median(sensor,'omitnan'));
            
            % further remove slow rates by satellite (clock drifting)
            %sensor_red = sensor - movmean(movmedian(sensor, 11), 17,'omitnan'); % ultra reduced data (requires longer arcs)
            %sensor(~isnan(sensor_red)) = sensor_red(~isnan(sensor_red));
            
            % Mark as jump any CS > 0.45 cycles / dependent on cycle slip thr
            if cs_size > 0
                id_cs = abs(sensor) > max(0.45, 0.7 * cs_size);
                % less safe but uses also std
                id_cs = id_cs | abs(sensor) > max(max(0.25, 0.55 * cs_size), repmat(6*std(sensor, 'omitnan'), size(sensor, 1), 1));
                
                if any(id_cs(:))
                    poss_fix = round(nan2zero(sensor(id_cs) / cs_size)) * cs_size;
                    
                    id_cs_t = sparse([], [], [], size(id_cs, 1), size(id_cs, 2));
                    id_cs_t(id_cs) = poss_fix;
                    
                    % try to repair
                    prn = unique(floor((find(id_cs_t) - 1) / size(id_cs_t, 1)) + 1);
                    
                    % correct tmp data
                    flattened_data(:, prn) = flattened_data(:, prn) - cumsum(nan2zero(id_cs_t(:, prn)));
                end
                
                data_jmp = flattened_data - data_in + data_trend;
            else
                data_jmp = 0;
            end
            % remove minor oscillations
            for c = 1 : size(flattened_data, 2)
                id_ok = find(~isnan(flattened_data(:, c)));
                if numel(id_ok) > 5
                    n_par = max(5, ceil(numel(id_ok) * rate / 150));
                    %tmp(:, s) = tmp(:, s) - Core_Utils.interp1LS(id_ok, tmp(id_ok, s), 5, (1 : size(tmp, 1))');
                    flattened_data(id_ok, c) = flattened_data(id_ok, c) - splinerMat(id_ok, flattened_data(id_ok, c), 150 / rate, 1e-3);
                else
                    flattened_data(:, c) = flattened_data(:, c) - strongMean(flattened_data(:, c), 0.9, 2);
                end
            end
            
            % remove common oscillations
            id_ok = mod(find(~isnan(flattened_data)) - 1, size(flattened_data, 1));
            [~, ~, ~, tmp_spline] = splinerMat(id_ok, flattened_data(~isnan(flattened_data)), 300 / rate, 1e-3, (1 : size(flattened_data, 1))');
            flattened_data = bsxfun(@minus,flattened_data,tmp_spline);
            
            if cs_size > 0
                flattened_data = flattened_data + data_jmp;
                data_jmp = round(movmedian(flattened_data, 5, 'omitnan') / cs_size) * cs_size;
                flattened_data = flattened_data - data_jmp;
            end
        end

        function [trk_ph_shift, trk_code] = repairPhases(this)
            % Get one single "mean" SNR per tracking/band
            % Defined as a polynomial of degree 2 in sin(el) space
            % Estimated in [0 : 90] degree
            %
            % SYNTAX
            %   [trk_ph_shift, trk_code] = this.repairPhases();
            %
            % EXAMPLE
            %   [trk_ph_shift, trk_code] = rec(5).work.repairPhases();
            
            this.log.addMarkedMessage('Applying cycle slip restore');
            this.sat.last_repair = zeros(size(this.obs, 1), 1); % init last_repair
            
            cs_size = this.state.getCycleSlipThr;
            %cs_size = 1;   % try to repair only full cycle slips (do not manage half cycle)
            cs_thr = 0.04;  % accept only correction with 96% of certainty
            
            i = 0;
            trk_ph_shift = [];
            trk_code = '';
            
            % getting diff phases minus synthesised (minus empirically estimated dt)
            % this is used as a sensor to determine which tracking is slipping
            [~, ph_red, id_ph_red] = this.getReducedPhases();
            %ph_red = bsxfun(@minus,ph_red,movmedian(ph_red))
            % system by system
            for sys_c = unique(this.system)
                
                % find all the phases of the current SS
                obs_code = this.getAvailableObsCode('L??', sys_c);
                bands = unique(obs_code(:,2))'; % get all the bands in the current SS
                
                % for each band
                for b_ch = bands
                    
                    % find all the phases with the current band
                    id_ph = this.findObservableByFlag(['L' b_ch '?'], sys_c);
                    obs_code = this.getAvailableObsCode(['L' b_ch '?'], sys_c);
                    
                    % get the prn to be used as index of a 3D matrix containing phases
                    [~, prn] = this.getSysPrn(this.go_id(id_ph));
                    trackings = unique(obs_code(:,3))';
                    
                    % with one tracking the phase shift cannot be estimated
                    if numel(trackings) > 0
                        i = i + 1; trk_ph_shift(i) = 0;
                        trk_code(i, :) = [sys_c ' ' b_ch trackings(1)];
                        
                        % store phases in a 3D matrix n_obs x n_sat x tracking mode
                        tmp_ph = nan(size(this.obs, 2), max(prn), numel(trackings));
                        tmp_ph_red = nan(size(this.obs, 2), max(prn), numel(trackings));
                        tmp_ph_dred = nan(size(this.obs, 2), max(prn), numel(trackings));
                        t = 0;
                        for t_ch = trackings
                            t = t + 1;
                            id_ph_trk{t} = this.findObservableByFlag(['L' b_ch t_ch], sys_c);
                            [~, prn] = this.getSysPrn(this.go_id(id_ph_trk{t}));
                            % original phase
                            tmp_ph(:, prn, t) = zero2nan(this.obs(id_ph_trk{t}, :)');
                            
                            % reduced phase
                            [~, id_red] = ismember(id_ph_trk{t}, id_ph_red);
                            tmp_ph_red(:, prn, t) = bsxfun(@rdivide, zero2nan(ph_red(:, id_red)), this.wl(id_ph_trk{t})');
                            tmp_ph_dred(:, prn, t) = Core_Utils.diffAndPred(tmp_ph_red(:, prn, t));
                            % find repairable cycle slips
                            %prn = unique(floor((find(id_cs_t) - 1) / size(id_cs_t, 1)) + 1);
                        end
                    end
                    
                    for t = 2 : numel(trackings)
                        ph_diff = diff(zero2nan(tmp_ph(:, :, [1 t])),1,3);
                        % find repairable cycle slips
                        sensor = Core_Utils.diffAndPred(ph_diff);
                        id_cs = abs(sensor) > 0.3;
                        
                        % possible cycle slip value
                        cs_val = round(sensor(id_cs));
                        
                        % figure; plot(sensor); hold on; plot(mod(find(id_cs), size(id_cs,1)), sensor(id_cs), 'og', 'MarkerSize', 10, 'LineWidth' , 3);
                        % ax = []; ax(1) = gca;
                        % for tf = 1 : numel(trackings)
                        %     tmp = Core_Utils.diffAndPred(tmp_ph_red(:,:,tf)); figure; plot(tmp); hold on; plot(mod(find(id_cs), size(id_cs,1)), tmp(id_cs), 'og', 'MarkerSize', 10, 'LineWidth' , 3);
                        %     ax(t+1) = gca;
                        % end
                        % linkaxes(ax, 'x');
                        clear sensor
                        
                        % Detect whose tracking mode is jumping
                        if any(id_cs(:))
                            for m = [1 t]
                                % Trying to repear the CS from this single difference observable could be risky
                                % but at the moment seems to always work
                                % whenever we find some cases when CS is no more detected
                                % remember to continue the investigation
                                sensor = tmp_ph_dred(:,:,m);
                                id_cs_t = sparse([], [], [], size(id_cs, 1), size(id_cs, 2));
                                id_cs_t(id_cs) = round(nan2zero(sensor(id_cs)));
                                
                                % try to repair
                                prn = unique(floor((find(id_cs_t) - 1) / size(id_cs_t, 1)) + 1);
                                
                                % correct tmp data
                                sensor = cumsum(id_cs_t(:, prn));
                                tmp_ph_red(:, prn, m) = tmp_ph_red(:, prn, m) - sensor;
                                tmp_ph_dred(:, prn, m) = Core_Utils.diffAndPred(tmp_ph_red(:, prn, m));
                                tmp_ph(:, prn, m) = tmp_ph(:, prn, m) - sensor;
                                
                                [~, id_obs] = ismember(prn, this.prn(id_ph_trk{m}));
                                this.obs(id_ph_trk{m}(id_obs), :) = nan2zero(zero2nan(this.obs(id_ph_trk{m}(id_obs), :)) - sensor');
                            end
                        end
                        
                        clear id_cs_t tmp id_cs
                        
                        if std(serialize(ph_diff - floor(ph_diff)), 'omitnan') < 0.1
                            ph_shift = median(serialize(ph_diff - floor(ph_diff)), 'omitnan');
                        else
                            ph_shift = median(serialize(ph_diff - floor(ph_diff - 1)), 'omitnan');
                        end
                        ph_shift = mod(round(ph_shift / 0.125) * 0.125, 1);
                        i = i + 1; trk_ph_shift(i) = ph_shift; % round to a quater of cycle (can it be totally float?)
                        trk_code(i, :) = [sys_c ' ' b_ch trackings(t)];
                        
                        % Correct the observations to compensate for the bias
                        this.obs(id_ph_trk{t}, :) = nan2zero(zero2nan(this.obs(id_ph_trk{t}, :)) - ph_shift);
                    end
                    
                    for t = 1 : numel(trackings)
                        % try single tracking repair
                        % trying to repear the CS from this single difference observable could be risky
                        % but at the moment seems to always work
                        % whenever we find some cases when CS is no more detected
                        % remember to continue the investigation
                        sensor = tmp_ph_dred(:,:,t) - median(serialize(tmp_ph_dred(:,:,t)), 'omitnan');  % remove the overall median on all epoch satellites
                        sensor = bsxfun(@minus, sensor, median(sensor,'omitnan')); % remove the satellite median for all satellite
                        
                        % further remove slow rates by satellite (clock drifting)
                        %sensor_red = sensor - movmean(movmedian(sensor, 11), 17,'omitnan'); % ultra reduced data (requires longer arcs)
                        %sensor(~isnan(sensor_red)) = sensor_red(~isnan(sensor_red));
                        
                        % Mark as jump any CS > 0.45 cycles / dependent on cycle slip thr
                        id_cs = abs(sensor) > max(0.45, 0.7 * cs_size);
                        
                        % do not repair CS at the beginning of an arc (not safe)
                        id_cs(id_cs((abs(id_cs) > 0) & ~flagShift(abs(sensor) > 0, 1))) = 0;
                        
                        if any(id_cs(:))
                            poss_fix = round(nan2zero(sensor(id_cs) / cs_size)) * cs_size;
                            % Keep only fixes that are sure at 95%
                            id_ok = (((sensor(id_cs) - poss_fix) / cs_size) < cs_thr);
                            if any(id_ok)
                                id_cs(id_cs) = id_cs(id_cs) & id_ok;
                                
                                id_cs_t = sparse([], [], [], size(id_cs, 1), size(id_cs, 2));
                                id_cs_t(id_cs) = poss_fix(id_ok);
                                
                                % try to repair
                                prn = unique(floor((find(id_cs_t) - 1) / size(id_cs_t, 1)) + 1);
                                
                                % correct tmp data
                                %sensor(:, prn) = sensor(:, prn) - id_cs_t(:, prn);
                                
                                [~, id_obs] = ismember(prn, this.prn(id_ph_trk{t}));
                                tmp_repair = cumsum(nan2zero(id_cs_t(:, prn)));
                                % Save last repair at the beginning of the buffer
                                if this.state.getBuffer() > 0
                                    this.sat.last_repair(id_ph_trk{t}(id_obs)) = tmp_repair(max(1, size(tmp_repair, 1) - round(this.state.getBuffer() / this.getRate) + 1), :);
                                else
                                    this.sat.last_repair(id_ph_trk{t}(id_obs)) = 0;
                                end
                                this.obs(id_ph_trk{t}(id_obs), :) = nan2zero(zero2nan(this.obs(id_ph_trk{t}(id_obs), :)) - tmp_repair');
                                tmp_ph_red(:, prn, t) = tmp_ph_red(:, prn, t) - tmp_repair;
                            end
                        end
                        
                        % Second cycle slip repair approach
                        [tmp, tmp_trend, tmp_jmp] = this.flattenPhases(squeeze(tmp_ph_red(:, :, t)));
                        prn = find(any(tmp_jmp));
                        [~, id_obs] = ismember(prn, this.prn(id_ph_trk{t}));
                        this.obs(id_ph_trk{t}(id_obs), :) = nan2zero(zero2nan(this.obs(id_ph_trk{t}(id_obs), :)) + tmp_jmp(:, prn)');
                    end
                end
            end
            %[~, ph_red, id_ph_red] = this.getReducedPhases(); figure; plot(ph_red);
            %keyboard
            %close(gcf);
        end
        
        function [quality, az, el] = getQuality(this, type)
            % get a quality index of the satellite data
            % type could be:
            %   'snr'
            %   '...'
            %
            % SYNTAX
            %  [quality] = this.getQuality()
            
            if nargin < 2
                type = 'snr';
            end
            switch lower(type)
                case 'snr'
                    quality = [];
                    az = [];
                    el = [];
                    for c = this.cc.SYS_C(this.cc.getActive)
                        [snr, id_snr] = this.getSNR(c,'1');
                        snr_temp = nan(size(snr, 1),this.cc.getMaxNumSat(c));
                        [~, prn] = this.getSysPrn(this.go_id(id_snr));
                        snr_temp(:, prn) = snr;
                        quality = [quality snr_temp]; %#ok<AGROW>
                        if nargout > 1
                            az_temp = nan(size(snr, 1),this.cc.getMaxNumSat(c));
                            az_temp(:, prn) = this.sat.az;
                            az = [az az_temp];
                            el_temp = nan(size(snr, 1),this.cc.getMaxNumSat(c));
                            el_temp(:, prn) = this.sat.el;
                            el = [el el_temp];
                        end                        
                    end
                    if ~isempty(quality)
                        quality = quality(this.getIdSync, :);
                        if nargout > 1
                            az = az(this.getIdSync, :);
                            el = el(this.getIdSync, :);
                        end
                    end
            end
        end
        
        function [obs, idx, snr, cs] = getObs(this, flag, sys_c, prn)
            % get observation and index corresponfing to the flag
            % SYNTAX this.findObservableByFlag(flag, <system>)
            if nargin > 3
                idx = this.findObservableByFlag(flag, sys_c, prn);
            elseif nargin > 2
                idx = this.findObservableByFlag(flag, sys_c);
            else
                idx = this.findObservableByFlag(flag);
            end
            obs = zero2nan(this.obs(idx,:));
            if nargout > 2
                if nargin > 3
                    idx_snr = this.findObservableByFlag(['S' flag(2:end)], sys_c, prn);
                elseif nargin > 2
                    idx_snr = this.findObservableByFlag(['S' flag(2:end)], sys_c);
                else
                    idx_snr = this.findObservableByFlag(['S' flag(2:end)]);
                end
                go_id_obs = this.go_id(idx);
                go_id_snr = this.go_id(idx_snr);
                snr_uns = this.obs(idx_snr,:);
                [~,io,is] = intersect(go_id_obs,go_id_snr);
                snr = nan(size(obs));
                snr(io,:) = snr_uns(is,:);
                
            end
            if nargout > 3 
                if flag(1) == 'L'
                    [~,~,idx_ph] = this.getPhases();
                    idx_ph = find(idx_ph);
                    [~,idx_o,idx_cs] = intersect(idx,idx_ph);
                    cs = this.sat.cicle_slip_ph_by_ph(:,idx_cs)';
                else
                    cs = [];
                end
            end
        end
        
        function id = findObservableByFlag(this, flag, sys_c, prn)
            % Search the id (aka row) of the obs with a certain flag
            % Supporting wildcard "?"
            %
            % SYNTAX
            %   id = this.findObservableByFlag(flag, <system>, <prn>)
            %   id = this.findObservableByFlag(flag, <go_id>)
            %
            % EXAMPLE
            %   id = this.findObservableByFlag('L1C');
            %   id = this.findObservableByFlag('?2C');
            
            if isempty(this.obs_code)
                id = [];
            else
                flag = [flag '?' * char(ones(1, 3 - size(flag, 2)))];
                
                lid = iif(flag(1) == '?', true(size(this.obs_code, 1), 1), this.obs_code(:, 1) == flag(1)) & ...
                    iif(flag(2) == '?', true(size(this.obs_code, 1), 1), this.obs_code(:, 2) == flag(2)) & ...
                    iif(flag(3) == '?', true(size(this.obs_code, 1), 1), this.obs_code(:, 3) == flag(3));
                if nargin == 3 && isnumeric(sys_c) % its a goid !!
                    lid = lid & (this.go_id == sys_c);
                else
                    if nargin > 2 && ~isempty(sys_c)
                        lid = lid & (this.system == sys_c)';
                    end
                    if nargin > 3 && ~isempty(prn)
                        lid = lid & (this.prn == prn);
                    end
                end
                
                id = find(lid);
            end
        end
        
        function obs_set = getPrefObsSetCh(this, flag, system)
            [obs, idx, snr, cycle_slips] = this.getPrefObsCh(flag, system, 1);
            if isempty(obs)
                
                obs_set = Observation_Set();
            else
                go_ids = this.getGoId(system, this.prn(idx)');
                if ~isempty(this.sat.el) && ~isempty(this.sat.az)
                    el = this.sat.el(:, go_ids);
                    az = this.sat.az(:, go_ids);
                else
                    az = [];
                    el = [];
                end
                obs_set = Observation_Set(this.time.getCopy(), obs' ,[this.system(idx)' this.obs_code(idx,:)], this.wl(idx)', el, az, this.prn(idx)');
                obs_set.cycle_slip = cycle_slips';
                obs_set.snr = snr';
                sigma = this.rec_settings.getStd(system, obs_set.obs_code(1,2:4));
                obs_set.sigma = sigma*ones(size(obs_set.prn));
            end            
        end
        
        function [obs, idx, snr, cycle_slips] = getPrefObsCh(this, flag, system, max_obs_type)
            % get observation index corresponfing to the flag using best
            % channel according to the definition in GPS_SS, GLONASS_SS, ...
            % SYNTAX this.findObservableByFlag(flag, <system>)
            obs = [];
            idx = [];
            snr = [];
            cycle_slips = [];
            if length(flag) == 3
                idx = sum(this.obs_code == repmat(flag,size(this.obs_code,1),1),2) == 3;
                idx = idx & (this.system == system)';
                %this.legger.addWarning(['Unnecessary Call obs_type already determined, use findObservableByFlag instead'])
                [obs,idx] = this.getObs(flag, system);
            elseif length(flag) >= 2
                sys_idx = (this.system == system)';
                sys = this.cc.getSys(system);
                band = find(sys.CODE_RIN3_2BAND == flag(2));
                if isempty(band)
                    this.log.addWarning('Obs not found',200);
                    obs = [] ; idx = [];
                    return;
                end
                preferences = sys.CODE_RIN3_ATTRIB{band}; % get preferences
                sys_obs_code = this.obs_code(sys_idx,:); % get obs code for the given system
                sz = size(sys_obs_code, 1);
                complete_flags = [];
                if nargin < 4
                    max_obs_type = length(preferences);
                end
                % find the best flag present
                for j = 1 : max_obs_type
                    for i = 1:length(preferences)
                        if sum(sum(sys_obs_code == repmat([flag preferences(i)],sz,1),2)==3)>0
                            complete_flags = [complete_flags; flag preferences(i)];
                            preferences(i) = [];
                            break
                        end
                    end
                end
                if isempty(complete_flags)
                    this.log.addWarning('Obs not found',200);
                    obs = [] ; idx = [];
                    return;
                end
                
                max_obs_type = size(complete_flags,1);
                idxes = [];
                prn = [];
                for j = 1 : max_obs_type
                    flags = repmat(complete_flags(j,:), size(this.obs_code,1), 1);
                    idxes = [idxes  (sum(this.obs_code == flags,2) == 3) & this.system' == system];
                    prn = unique( [prn; this.prn(idxes(: , end )>0)]);
                end
                
                n_opt = size(idxes,2);
                n_epochs = size(this.obs,2);
                obs = zeros(length(prn)*n_opt,n_epochs);
                snr = zeros(size(obs));
                if flag(1) == 'L'
                    cycle_slips = sparse(size(obs,1),size(obs,2));
                end
                
                flags = zeros(length(prn)*n_opt,3);
                
                for s = 1:length(prn) % for each satellite and each epoch find the best (but put them on different lines)
                    sat_idx = sys_idx & this.prn == prn(s);
                    
                    tmp_obs = zeros(n_opt,n_epochs);
                    take_idx = ones(1,n_epochs) > 0;
                    for i = 1 : n_opt
                        c_idx = idxes(:, i) & sat_idx;
                        snr_idx = (strLineMatch(this.obs_code, ['S' complete_flags(i,2:3)]) | strLineMatch(this.obs_code, ['S' complete_flags(i,2) ' '])  ) & sat_idx;
                        if sum(c_idx)>0
                            obs((s-1)*n_opt+i,take_idx) = this.obs(c_idx,take_idx);
                            if sum(snr_idx)
                                snr((s-1)*n_opt+i,take_idx) = this.obs(snr_idx,take_idx);
                            else
                                snr((s-1)*n_opt+i,take_idx) = 1;
                            end
                            if ~isempty(this.sat.outliers_ph_by_ph) && flag(1) == 'L' % take off outlier
                                ph_idx = this.ph_idx == find(c_idx);
                                if sum(ph_idx) > 0
                                obs((s-1)*n_opt+i,this.sat.outliers_ph_by_ph(:,ph_idx)) = 0;
                                snr((s-1)*n_opt+i,this.sat.outliers_ph_by_ph(:,ph_idx)) = 0;
                                cycle_slips((s-1)*n_opt+i,:) = this.sat.cicle_slip_ph_by_ph(:,ph_idx)';
                                end
                            end
                            flags((s-1)*n_opt+i,:) = this.obs_code(c_idx,:);
                        end
                        take_idx = take_idx & obs((s-1)*n_opt+i,:) == 0;
                    end
                end
                prn = reshape(repmat(prn,1,n_opt)',length(prn)*n_opt,1);
                % remove all empty lines
                empty_idx = sum(obs==0,2) == n_epochs;
                obs(empty_idx,:) = [];
                snr(empty_idx,:) = [];
                prn(empty_idx,:) = [];
                if flag(1) == 'L'
                    cycle_slips(empty_idx,:) = [];
                end
                flags(empty_idx,:) = [];
                flags = char(flags);
                idx = zeros(length(prn),1);
                for i = 1:length(prn)
                    idx(i) = find(sys_idx & this.prn == prn(i) & sum(this.obs_code == repmat(flags(i,:) ,size(this.obs_code,1) ,1),2) == 3);
                end
            else
                this.log.addError(['Invalid length of obs code(' num2str(length(flag)) ') can not determine preferred observation'])
            end
        end
        
        function [obs_set] = getPrefObsCh_os(this, flag, system)
            [o, i, s, cs] = this.getPrefObsCh(flag, system, 1);
            el = this.getEl();
            az = this.getAz();
            if ~isempty(el)
                el = el(: ,this.go_id(i));
                az = az(: ,this.go_id(i));
            end
            ne = size(o,2);
            obs_set = Observation_Set(this.time.getCopy(), o' .* repmat(this.wl(i,:)',ne,1) , [this.system(i)' this.obs_code(i,:)], this.wl(i,:), el, az, this.prn(i));
            obs_set.cycle_slip = cs';
            obs_set.snr = s';
            obs_set.sigma = this.rec_settings.getStd(system, [flag '_'])*ones(size(this.prn(i)));
        end
        
        % ---------------------------------------
        %  Two Frequency observation combination
        %  Warappers of getTwoFreqComb function
        % ---------------------------------------
        
        function [obs_set] = getTwoFreqComb(this, flag1, flag2, fun1, fun2, know_comb)
            %INPUT flag1 : either observation code (e.g. GL1) or observation set
            %       flag1 : either observation code (e.g. GL2) or observation set
            %       fun1  : function of the two wavelegnth to be applied to
            %       compute the first frequncy coefficient
            %       fun2  : function of the two wavelegnth to be applied to
            %       compute the second frequency coefficient
            if nargin  < 6
                know_comb = 'none';
            end
            if ischar(flag1)
                system = flag1(1);
                if length(flag1) < 4 % tracking not specified
                    [o1, i1, s1, cs1] = this.getPrefObsCh(flag1(2:3), system, 1);
                else
                    [o1, i1, s1, cs1] = this.getObs(flag1(2:end), system);
                end
                o1 = o1';
                s1 = s1';
                cs1 = cs1';
                if length(flag2) < 4 % tracking not specified
                    [o2, i2, s2, cs2] = this.getPrefObsCh(flag2(2:3), system, 1);
                else
                    [o2, i2, s2, cs2] = this.getObs(flag2(2:end), system);
                end
                o2 = o2';
                s2 = s2';
                cs2 = cs2';
                % get prn for both frequency
                p1 =  this.prn(i1);
                p2 =  this.prn(i2);
                w1 =  this.wl(i1);
                w2 =  this.wl(i2);
                oc1 = this.obs_code(i1(1),:);
                oc2 = this.obs_code(i2(1),:);
                % form cycle to meters
                if flag1(2) == 'L'
                    o1 = o1.*repmat(w1',size(o1,1),1);
                end
                if flag2(2) == 'L'
                    o2 = o2.*repmat(w2',size(o2,1),1);
                end
                sigma1 = repmat(this.rec_settings.getStd(system,this.obs_code(i1(1),:)),size(o1,2),1);
                sigma2 = repmat(this.rec_settings.getStd(system,this.obs_code(i2(1),:)),size(o2,2),1);
            elseif strcmp(class(flag1),'Observation_Set') %observation set
                o1 = flag1.obs;
                o2 = flag2.obs;
                s1 = flag1.snr;
                s2 = flag2.snr;
                sigma1 = flag1.sigma;
                sigma2 = flag2.sigma;
                cs1 = flag1.cycle_slip;
                cs2 = flag2.cycle_slip;
                p1 =  flag1.prn;
                p2 =  flag2.prn;
                w1 =  flag1.wl;
                w2 =  flag2.wl;
                obs_code = [];
                system = flag1.obs_code(1,1);
                oc1 = '   ';
                oc2 = '   ';
            end
            common_prns = intersect(p1, p2)';
            go_id = zeros(size(common_prns))';
            obs_out = zeros(size(o1,1), length(common_prns));
            snr_out = zeros(size(o1,1), length(common_prns));
            cs_out = zeros(size(o1,1), length(common_prns));
            az = zeros(size(o1,1), length(common_prns));
            el = zeros(size(o1,1), length(common_prns));
            obs_code = repmat([system oc1 oc2],length(common_prns),1);
            wl = zeros(1,length(common_prns),1);
            sigma = zeros(1,length(common_prns));
            for p = 1 : length(common_prns)
                ii1 = p1 == common_prns(p);
                ii2 = p2 == common_prns(p);
                alpha1 = fun1(w1(ii1), w2(ii2));
                alpha2 = fun2(w1(ii1), w2(ii2));
                obs_out(:, p) = nan2zero(alpha1 * zero2nan(o1(:,ii1)) + alpha2 * zero2nan(o2(:,ii2)));
                idx_obs = obs_out(:, p) ~=0;
                % get go id for the current sat
                c_go_id = this.getGoId(system, common_prns(p));
                go_id(p) = c_go_id;
                if ~isempty(this.sat.az)
                    az(idx_obs, p) = this.sat.az(idx_obs, c_go_id);
                else
                    az = [];
                end
                if ~isempty(this.sat.el)
                    el(idx_obs, p) = this.sat.el(idx_obs, c_go_id);
                else
                    el = [];
                end
                snr_out(:, p) = nan2zero(sqrt((alpha1.* zero2nan(s1(:, ii1))).^2 + (alpha2 .* zero2nan(s2(:, ii2))).^2));
                sigma(p) = sqrt((alpha1*sigma1(ii1))^2 + (alpha2*sigma2(ii2))^2);
                if isempty(cs1) && isempty(cs2) % cycle slips only if there is at least one phase observables
                    cs_out = [];
                    wl(p) = -1;
                elseif isempty(cs1)
                    cs_out = cs2;
                    wl(p) = alpha2 * w2(ii2);
                elseif isempty(cs2)
                    cs_out = cs1;
                    wl(p) = alpha1 * w1(ii1);
                else
                    cs_out(:, p) = cs2(:, ii2) | cs1(:, ii1);
                    if strcmp(know_comb,'IF')
                        [i,j] = rat(w2(ii2)/w1(ii1),0.001);
                        j= -j;
                    elseif strcmp(know_comb,'NL')
                        i = 1;
                        j = 1;
                    elseif strcmp(know_comb,'WL')
                        i = 1;
                        j = -1;
                    else
                        i = -w2(ii2)/2;
                        j = -w1(ii1)/2; %so wavelength is -1
                    end
                    wl(p) = w1(ii1)*w2(ii2)/(i*w2(ii2) + j*w1(ii1)); % see: https://www.tekmon.gr/online-gps-tutorial/1-4-1-linear-combinations-of-simultaneous-observations-between-frequencies
                end
            end
            obs_set = Observation_Set(this.time.getCopy(), obs_out ,obs_code, wl, el, az, common_prns);
            obs_set.go_id = go_id;
            obs_set.cycle_slip = cs_out;
            obs_set.snr = snr_out;
            obs_set.sigma = sigma;
        end
        
        function [obs_set] = getIonoFree(this,flag1,flag2,system)
            fun1 = @(wl1, wl2) wl2 ^ 2 / (wl2 ^ 2 - wl1 ^ 2);
            fun2 = @(wl1, wl2) - wl1^2/(wl2 ^ 2 - wl1 ^ 2);
            [obs_set] =  this.getTwoFreqComb([system flag1], [system flag2], fun1, fun2,'IF');
            obs_set.obs_code = [obs_set.obs_code repmat('I', size(obs_set.obs_code,1), 1)];
        end
        
        function [obs_set] = getNarrowLane(this,flag1,flag2,system)
            fun1 = @(wl1,wl2) wl2/(wl2+wl1);
            fun2 = @(wl1,wl2) wl1/(wl2+wl1);
            [obs_set] =  this.getTwoFreqComb([system flag1], [system flag2], fun1, fun2,'NL');
        end
        
        function [obs_set] = getWideLane(this,flag1,flag2,system)
            fun1 = @(wl1,wl2) wl2/(wl2-wl1);
            fun2 = @(wl1,wl2) - wl1/(wl2-wl1);
            [obs_set] =  this.getTwoFreqComb([system flag1],[system flag2], fun1, fun2,'WL');
        end
        
        function [obs_set] = getGeometryFree(this,flag1,flag2,system)
            if flag1(1) == 'C' &&  flag2(1) == 'C'
                % Code geometry free is C2 - C1 -> exchange the flags
                tmp = flag1;
                flag1 = flag2;
                flag2 = tmp;
            end
            fun1 = @(wl1,wl2) 1;
            fun2 = @(wl1,wl2) -1;
            [obs_set] =  this.getTwoFreqComb([system flag1],[system flag2], fun1, fun2);
        end
        
        function [obs_set] = getPrefGeometryFree(this,obs_type,system)
            iono_pref = this.cc.getSys(system).IONO_FREE_PREF;
            is_present = false(size(iono_pref,1),1);
            for i = 1 : size(iono_pref,1)
                % check if there are observation for the selected channel
                if sum(iono_pref(i,1) == this.obs_code(:,2) & obs_type == this.obs_code(:,1)) > 0 && sum(iono_pref(i,2) == this.obs_code(:,2) & obs_type == this.obs_code(:,1)) > 0
                    is_present(i) = true;
                end
            end
            iono_pref = iono_pref(is_present,:);
            [obs_set]  = this.getGeometryFree([obs_type iono_pref(1,1)], [obs_type iono_pref(1,2)], system);
        end
        
        function [obs_set] = getMelWub(this, freq1, freq2, system)
            
            fun1 = @(wl1,wl2) 1;
            fun2 = @(wl1,wl2) -1;
            [obs_set1] = this.getWideLane(['L' freq1],['L' freq2], system); %widelane phase
            [obs_set2] = this.getNarrowLane(['C' freq1],['C' freq2], system); %narrowlane code
            [obs_set] =  this.getTwoFreqComb(obs_set1, obs_set2, fun1, fun2);
        end
        
        function [obs_set]  = getPrefIonoFree(this, obs_type, system)
            % get Preferred Iono free combination for the two selcted measurements
            % SYNTAX [obs] = this.getIonoFree(flag1, flag2, system)
            iono_pref = this.cc.getSys(system).IONO_FREE_PREF;
            is_present = false(size(iono_pref,1),1);
            for i = 1 : size(iono_pref,1)
                % check if there are observations for the selected channel
                if sum(iono_pref(i,1) == this.obs_code(:,2) & obs_type == this.obs_code(:,1)) > 0 && sum(iono_pref(i,2) == this.obs_code(:,2) & obs_type == this.obs_code(:,1)) > 0
                    is_present(i) = true;
                end
            end
            iono_pref = iono_pref(is_present,:);
            if isempty(iono_pref)
                obs_set = Observation_Set();
            else
                obs_set = this.getIonoFree([obs_type iono_pref(1,1)], [obs_type iono_pref(1,2)], system);
            end
        end
        
        function [obs_set]  = getSmoothIonoFreeAvg(this, obs_type, sys_c)
            % get Preferred Iono free combination for the two selcted measurements
            % SYNTAX [obs] = this.getIonoFree(flag1, flag2, system)
            iono_pref = this.cc.getSys(sys_c).IONO_FREE_PREF;
            is_present = false(size(iono_pref,1),1);
            for i = 1 : size(iono_pref,1)
                % check if there are observation for the selected channel
                if sum(iono_pref(i,1) == this.obs_code(:,2) & obs_type == this.obs_code(:,1)) > 0 && sum(iono_pref(i,2) == this.obs_code(:,2) & obs_type == this.obs_code(:,1)) > 0
                    is_present(i) = true;
                end
            end
            iono_pref = iono_pref(is_present,:);
            [ismf_l1]  = this.getSmoothIonoFree([obs_type iono_pref(1,1)], sys_c);
            [ismf_l2]  = this.getSmoothIonoFree([obs_type iono_pref(1,2)], sys_c);
            
            %             id_ph = Core_Utils.code2Char2Num(this.getAvailableObsCode) == Core_Utils.code2Char2Num('L5');
            %             if any(id_ph)
            %                [ismf_l5]  = this.getSmoothIonoFree([obs_type '5'], sys_c);
            %             end
            
            fun1 = @(wl1,wl2) 0.65;
            fun2 = @(wl1,wl2) 0.35;
            [obs_set] =  this.getTwoFreqComb(ismf_l1, ismf_l2, fun1, fun2);
            obs_set.iono_free = true;
            obs_set.obs_code = repmat(ismf_l1.obs_code(1,:),length(obs_set.prn),1);
        end
        
        function [obs_set, widelane_amb_mat, widelane_amb_fixed] = getIonoFreeWidelaneFixed(this)
            % gte the iono free with widelane fixed (GPS only)
            %
            % SYNTAX
            % [obs_set, widelane_amb] = this.getIonoFreeWidelaneFixed()
            [widelane_amb_mat, widelane_amb_fixed] = getWidelaneAmbEst(this)
            wl =  this.getWideLane('L1','L2','G');
            wl.obs = wl.obs  + mwb.wl(1)*widelane_amb_mat(:,wl.go_id);
            % 2) get the narrowlane
            nl = this.getNarrowLane('L1','L2','G');
            % 3) get the iono free
            fun1 = @(wl1,wl2) 1/2;
            fun2 = @(wl1,wl2) 1/2;
            obs_set = this.getTwoFreqComb(wl, nl, fun1, fun2);
            obs_set.obs_code = repmat('GL1CL2WI',size(obs_set.obs_code,1),1); % to be generalized
            
        end
        
        function  [widelane_amb_mat, widelane_amb_fixed, wsb_rec] = getWidelaneAmbEst(this)
            % 1) get widelane and fix the ambiguity
            % remove grupo delay
            this.remGroupDelay();
            % estaimet WL
            mwb = this.getMelWub('1','2','G');
            wl_cycle = zeros(size(mwb.obs,1),this.cc.getGPS.N_SAT);
            wl_cycle(:,mwb.go_id) = mwb.obs;
            wl_cycle(:,mwb.go_id) = wl_cycle(:,mwb.go_id)./repmat(mwb.wl,size(mwb.obs,1),1);
            wsb = this.sat.cs.getWSB(this.getCentralTime());
            % take off wsb
            wl_cycle = zero2nan(wl_cycle) + repmat(wsb,size(mwb.obs,1),1);
            
            [wl_cycle(~isnan(wl_cycle)), wsb_rec] = Core_Utils.getFracBias(wl_cycle(~isnan(wl_cycle)));
            % apply tyhe cycle to the widelane
            wl =  this.getWideLane('L1','L2','G');
            amb_idx = nan(size(wl.obs,1),this.cc.getGPS.N_SAT);
            amb_idx(:, wl.go_id) = wl.getAmbIdx();
            n_amb = max(max(amb_idx));
            widelane_amb_mat = nan(size(mwb.obs,1),this.cc.getGPS.N_SAT);
            widelane_amb_fixed = false(size(mwb.obs,1),this.cc.getGPS.N_SAT);%false(n_amb,1);
            for i = 1 : n_amb
                idx = amb_idx == i;
                est_amb_float = mean(wl_cycle(idx));
                est_amb_fix = round(est_amb_float);
                est_amb_std = mean(abs(wl_cycle(idx)- est_amb_fix));
                widelane_amb_mat(idx) = est_amb_fix;
                if abs(est_amb_float - est_amb_fix) < 0.3 %% to consider a better statistics
                    widelane_amb_fixed(idx) = true;
                end
            end
            this.applyGroupDelay();
        end
        
        function [obs_set]  = getSmoothIonoFree(this, obs_type, sys_c)
            % get Preferred Iono free combination for the two selected measurements
            %
            % SYNTAX
            %   [obs_set]  = this.getSmoothIonoFree(this, obs_type, sys_c)
            
            gf_ph = this.getPrefGeometryFree('L',sys_c); %widelane phase
            [gf_pr] = this.getPrefGeometryFree('C',sys_c); %widelane phase
            idx_nan = gf_ph.obs == 0;
            
            el = gf_ph.el / 180 * pi;
            gf_ph.obs = this.ionoCodePhaseSmt(zero2nan(gf_pr.obs), gf_pr.sigma.^2, zero2nan(gf_ph.obs), gf_ph.sigma.^2, gf_ph.getAmbIdx(), 0.01, el);
            
            gf_ph.obs(idx_nan) = nan;
            %gf.obs = this.smoothSatData([], [], zero2nan(gf.obs), gf.cycle_slip);
            gf_ph.obs = this.smoothSatData([], [], zero2nan(gf_ph.obs), false(size(gf_ph.cycle_slip)), [], 300 / gf_ph.time.getRate); % <== supposing no more cycle slips
            
            [obs_set1] = getPrefObsCh_os(this, obs_type, sys_c);
            ifree = this.cc.getSys(sys_c).getIonoFree();
            coeff = [ifree.alpha2 ifree.alpha1];
            fun1 = @(wl1, wl2) 1;
            band = this.cc.getBand(sys_c, obs_type(2));
            fun2 = @(wl1, wl2) + coeff(band);
            [obs_set] =  this.getTwoFreqComb(obs_set1, gf_ph, fun1, fun2);
            obs_set.iono_free = true;
            synt_ph = this.getSyntTwin(obs_set);
            %%% tailored outlier detection
            sensor_ph = Core_Utils.diffAndPred(zero2nan(obs_set.obs) - zero2nan(synt_ph));
            sensor_ph = sensor_ph./(repmat(serialize(obs_set.wl)',size(sensor_ph,1),1));
            %
            %             % subtract median (clock error)
            sensor_ph = bsxfun(@minus, sensor_ph, median(sensor_ph, 2, 'omitnan'));
            %
            %
            %             % outlier when they exceed 0.5 cycle
            poss_out_idx = abs(sensor_ph) > 0.5;
            poss_out_idx = poss_out_idx & ~(obs_set.cycle_slip);
            obs_set.obs(poss_out_idx) = 0;
            obs_set.obs_code = repmat(gf_ph.obs_code(1,:),length(obs_set.prn),1);
        end
        
        function [obs_set]  = getPrefMelWub(this, system)
            % get Preferred Iono free combination for the two selcted measurements
            % SYNTAX [obs] = this.getIonoFree(flag1, flag2, system)
            iono_pref = this.cc.getSys(system).IONO_FREE_PREF;
            is_present = zeros(size(iono_pref,1),1) < 1;
            for i = size(iono_pref,1)
                % check if there are observation for the selected channel
                if sum(iono_pref(i,1) == this.obs_code(:,2) & iono_pref(i,1) == this.obs_code(:,1)) > 0 && sum(iono_pref(i,2) == this.obs_code(:,2) & iono_pref(i,1) == this.obs_code(:,1)) > 0
                    is_present(i) = true;
                end
            end
            iono_pref = iono_pref(is_present,:);
            [obs_set]  = this.getMelWub([iono_pref(1,1)], [iono_pref(1,2)], system);
        end
        
        function [rec_out_ph] = getObsOutSat(this)
            % get the phase outlier to be putted in the results
            % default outlier are the ones on the iono free combination
            if ~isempty(this.sat.outliers)
                rec_out_ph = this.sat.outliers(this.getIdSync(),:);
            else
                rec_out_ph = zeros(length(this.getIdSync()), this.cc.getMaxNumSat());
            end
        end
        
        function [rec_cs_ph] = getObsCsSat(this)
            % get the phase outlier to be putted in the results
            % default outlier are the ones on the iono free combination
            if ~isempty( this.sat.cycle_slip)
                rec_cs_ph = this.sat.cycle_slip(this.getIdSync(),:);
            else
                rec_cs_ph = zeros(length(this.getIdSync()), this.cc.getMaxNumSat());
            end
        end
        
        function [range, XS_loc] = getSyntObs(this, go_id_list)
            %  get the estimate of one measurmenet based on the
            % current postion
            % INPUT
            % EXAMPLE:
            %   this.getSyntObs(1,go_id)
            n_epochs = size(this.obs, 2);
            if nargin < 2
                go_id_list = 1 : this.parent.cc.getMaxNumSat();
            end
            range = zeros(length(go_id_list), n_epochs);
            XS_loc = [];
            for i = 1 : length(go_id_list)
                go_id = go_id_list(i);
                XS_loc = this.getXSLoc(go_id);
                range_tmp = sqrt(sum(XS_loc.^2,2));
                range_tmp = range_tmp + nan2zero(this.sat.err_tropo(:,go_id));
                
                XS_loc(isnan(range_tmp),:) = [];
                %range = range';
                range(i,:) = nan2zero(range_tmp)';
            end
        end
        
        function synt_pr_obs = getSyntCurObs(this, phase, sys_c)
            %  get syntetic observation for code or phase
            obs_type = {'code', 'phase'};
            this.log.addMessage(this.log.indent(sprintf('Synthesising %s observations', obs_type{phase + 1})));
            if nargin < 3
                sys_c = this.cc.sys_c;
            end
            
            if phase
                idx_obs = this.findObservableByFlag('L');
            else
                idx_obs = this.findObservableByFlag('C');
            end
            sys = this.system(idx_obs);
            
            for i = numel(sys) : -1 : 1
                if ~ismember(sys(i), sys_c)
                    sys(i) = [];
                    idx_obs(i) = [];
                end
            end
            
            synt_pr_obs = zeros(length(idx_obs), size(this.obs,2));
            go_id = this.go_id(idx_obs);
            u_sat = unique(go_id);
            %this.updateAllAvailIndex();
            if ~this.isMultiFreq()
                this.updateErrIono();
            end
            if sum(this.xyz) ~=0
                this.updateErrTropo();
            end
            % for each unique go_id
            for i = u_sat'
                
                range = this.getSyntObs( i);
                
                sat_idx = find(go_id == i);
                % for all the obs with the same go_id
                for j = sat_idx'
                    o = (idx_obs == idx_obs(j));
                    c_obs_idx = idx_obs(j); % index of the observation we are currently processing
                    ep_idx = this.obs(c_obs_idx, :) ~= 0;
                    synt_pr_obs(o, ep_idx) = range(ep_idx);
                end
                
            end
        end
        
        function synt_ph = getSyntPhases(this, sys_c)
            % get current value of syntetic phase, in case not present update it
            if isempty(this.synt_ph)
                this.updateSyntPhases();
            end
            synt_ph = this.synt_ph;
            synt_ph(this.sat.outliers_ph_by_ph) = nan;
            if nargin == 2
                synt_ph = synt_ph(:, this.system(this.obs_code(:, 1) == 'L') == sys_c');
            end
        end
        
        function [dt_ph, ph_diff, id_ph] = getReducedPhases(this, mode)
            % Get the empirical clock from phases
            % Eventually return also the reduced phases
            % (reduced by synth + dt)
            %
            % SYNTAX
            %   [dt_ph, ph_diff, id_ph] = this.getReducedPhases()
            
            if nargin < 2 || ~isempty(mode)
                mode = 'rmSlow';
            end
            
            [ph, wl, id_ph] = this.getPhases();
            
            id_ph = find(id_ph);
            phs = this.getSyntPhases();
            
            % First approach, trust the derivate
            % do I trust PPP clock?
            tmp = Core_Utils.diffAndPred(strongDeTrend(zero2nan(ph) - zero2nan(phs)));
            % removing bias is dangerous when computed with arcs with different lengths
            %bias = median(tmp, 'omitnan');
            %tmp = bsxfun(@minus, tmp, bias);
            dt_ph = strongMean(tmp', 1, 0.95, 2)';
                       
            switch mode
                case 'rmSlow'
                    % remove slow effects
                    id = (1 : numel(dt_ph))';
                    ph_diff = bsxfun(@minus, zero2nan(ph) - zero2nan(phs), cumsum(nan2zero(dt_ph)));
                    tmp = Core_Utils.diffAndPred(ph_diff);
                    
                    %slow effects
                    [~, ~, ~, dt_lf] = splinerMat([], median(movmedian(tmp,5),2,'omitnan'), 3600 / this.getRate, 0.001, 0 : (size(tmp,1) - 1));
                    dt_ph = zero2nan(dt_ph + dt_lf - mean(zero2nan(dt_ph + dt_lf), 'omitnan'));
            end
            
            %dt_ph = cumsum(nan2zero(dt_ph) - mean(dt_ph, 'omitnan') + mean(bias, 'omitnan'));
            dt_ph = cumsum(nan2zero(dt_ph) - mean(dt_ph, 'omitnan'));
            dt_ph = dt_ph - mean(dt_ph, 'omitnan') + mean(serialize(diff(zero2nan(ph) - zero2nan(phs))), 'omitnan');
            ph_diff = bsxfun(@minus, zero2nan(ph) - zero2nan(phs), dt_ph);
        end
        
        function synt_pr_obs = getSyntPrObs(this, sys_c)
            if nargin < 2
                sys_c = this.cc.sys_c;
            end
            synt_pr_obs = zero2nan(this.getSyntCurObs(false, sys_c)');
        end
        
        function [synt_obs, xs_loc] = getSyntTwin(this, obs_set)
            %  get the syntethic twin for the observations
            % contained in obs_set
            % WARNING: the time of the observation set and the time of
            % receiver has to be the same
            synt_obs = zeros(size(obs_set.obs));
            xs_loc   = zeros(size(obs_set.obs,1), size(obs_set.obs,2),3);
            idx_ep_obs = obs_set.getTimeIdx(this.time.first, this.getRate);
            for i = 1 : size(synt_obs,2)
                go_id = obs_set.go_id(i);
                [range, xs_loc_t] = this.getSyntObs( go_id);
                idx_obs = obs_set.obs(:, i) ~= 0;
                idx_obs_r = idx_ep_obs(idx_obs); % <- to which epoch in the receiver the observation of the satellites in obesrvation set corresponds?
                idx_obs_r_l = false(size(range)); % get the logical equivalent
                idx_obs_r_l(idx_obs_r) = true;
                range_idx = range ~= 0;
                xs_idx = idx_obs_r_l(range_idx);
                synt_obs(idx_obs, i) = range(idx_obs_r);
                xs_loc(idx_obs, i, :) = permute(xs_loc_t(xs_idx, :),[1 3 2]);
            end
        end
        
        function id_sync = getIdSync(this)
            % MultiRec: works on an array of receivers
            % SYNTAX
            %  id_sync = this.getIdSync()
            id_sync = [];
            
            offset = 0;
            n_rec = numel(this);
            for r = 1 : n_rec
                id_sync = [id_sync; this(r).id_sync(:) + offset]; %#ok<AGROW>
                offset = offset + this.length();
            end
            if islogical(id_sync)
                id_sync = find(id_sync);
            end
        end
    end
    
    % ==================================================================================================================================================
    %% METHODS SETTERS
    % ==================================================================================================================================================
    methods
        function setStatic(this)
            % Set the internal status of the Receiver as static
            % SYNTAX
            %   this.setStatic()
            this.parent.static = true;
        end
        
        function setDynamic(this)
            % Set the internal status of the Receiver as dynamic
            % SYNTAX
            %   this.setDynamic()
            this.parent.static = false;
        end
        
        function setDoppler(this, dop, wl, id_dop)
            % set the snr observations
            % SYNTAX [pr, id_pr] = this.setDoppler(<sys_c>)
            % SEE ALSO:  getDoppler
            dop = bsxfun(@rdivide, zero2nan(dop'), wl);
            this.obs(id_dop, :) = nan2zero(dop');
        end
        
        function setSNR(this, snr, id_snr)
            % set the snr observations
            % SYNTAX [pr, id_pr] = this.setSNR(<sys_c>)
            % SEE ALSO:  getSNR
            this.obs(id_snr, :) = nan2zero(snr');
        end
        
        function setPhases(this, ph, wl, id_ph)
            % set the phases observations in meter (not cycles)
            % SYNTAX setPhases(this, ph, wl, id_ph)
            % SEE ALSO: getPhases getPseudoRanges setPseudoRanges
            
            ph = bsxfun(@rdivide, zero2nan(ph'), wl);
            this.obs(id_ph, :) = nan2zero(ph);
        end
        
        function resetSynthPhases(this)
            % recompute synhtesised phases
            %
            % SYNTAX
            %   this.resetSynthPhases()
            
            this.synt_ph = [];
            this.updateSyntPhases();
        end
        
        function injectObs(this, obs, wl, f_id, obs_code, go_id)
            % Injecting observations into Receiver
            % This routine have been written for Core_SEID
            %
            % SINTEX:
            %   this.injectObs(obs, wl, f_id, obs_code, go_id);
            
            if size(obs, 2) ~= size(this.obs, 2)
                this.log.addError(sprintf('Observation injection not possible, input contains %d epochs while obs contains %d epochs', size(obs, 2), size(this.obs, 2)));
            else
                go_id = go_id(:);
                f_id = f_id(:);
                wl = wl(:);
                assert(size(obs, 1) == numel(go_id), 'Observation injection input "go_id" parameters size error');
                
                this.obs = [this.obs; obs];
                this.go_id = [this.go_id; go_id];
                this.active_ids = [this.active_ids; true(size(go_id))];
                if numel(f_id) == 1
                    this.f_id = [this.f_id; f_id * ones(size(go_id))];
                else
                    assert(size(obs, 1) == numel(f_id), 'Observation injection input "f_id" parameters size error');
                    this.f_id = [this.f_id; f_id];
                end
                if numel(wl) == 1
                    this.wl = [this.wl; wl * ones(size(go_id))];
                else
                    assert(size(obs, 1) == numel(wl), 'Observation injection input "wl" parameters size error');
                    this.wl = [this.f_id; wl];
                end
                
                [sys, prn] = this.getSysPrn(go_id);
                this.prn = [this.prn; prn];
                this.system = [this.system sys'];
                
                if size(obs_code,1) == 1
                    this.obs_code = [this.obs_code; repmat(obs_code, size(go_id, 1), 1)];
                else
                    assert(size(obs, 2) == numel(wl), 'Observation injection input "wl" parameters size error');
                    this.obs_code = [this.obs_code; obs_code];
                end
                this.resetSynthPhases();
            end
        end
        
        function setPseudoRanges(this, pr, id_pr)
            % set the pseudo ranges observations in meter (not cycles)
            % SYNTAX [pr, id_pr] = this.getPseudoRanges(<sys_c>)
            % SEE ALSO: getPhases setPhases getPseudoRanges
            this.obs(id_pr, :) = nan2zero(pr');
        end
        
        function setXYZ(this, xyz)
            %description set xyz and upadte godetic coordinates
            this.xyz = xyz;
            this.updateCoordinates();
        end
        
        function setActiveSys(this, sys_list)
            % set the active systems to be used for the computations
            % SYNTAX this.setActiveSys(sys_list)
            
            % Select only the systems still present in the file
            this.cc.setActive(sys_list);
        end
        
        function setOutLimits(this, out_start, out_end)
            % description  set time loimits for output
            %
            % SYNTAX
            % this. setOutLimits(out_start, out_end)
            this.out_start_time = out_start;
            this.out_stop_time = out_end;
        end
    end
    
    % ==================================================================================================================================================
    %% METHODS UPDATERS
    % ==================================================================================================================================================
    methods
        function updateCoordinates(this)
            % upadte lat lon e ortometric height
            [this.lat, this.lon, this.h_ellips, this.h_ortho] = this.getMedianPosGeodetic();
        end
        
        function updateSyntPhases(this, sys_c)
            % update the content of the syntetic phase
            if nargin < 2
                sys_c = this.cc.sys_c;
            end
            synt_ph_obs = zero2nan(this.getSyntCurObs( true, sys_c)');
            synt_ph_obs(this.sat.outliers_ph_by_ph) = nan;
            this.synt_ph = synt_ph_obs;
        end
        
        function updateStatus(this)
            % Compute the other useful status array of the receiver object
            %
            % SYNTAX
            %   this.updateStatus();
            
            [~, ss_id] = ismember(this.system, this.cc.sys_c);
            this.n_freq = numel(unique(this.f_id));
            ss_offset = cumsum([0 this.cc.n_sat(1:end-1)]);
            ss_offset_id = ss_offset(ss_id');
            if ~isempty(ss_offset_id)
                ss_offset_id = serialize(ss_offset_id); %%% some time second vector is a colum some time is a line reshape added to uniform
            end
            this.go_id = this.prn + ss_offset_id;
            this.n_sat = numel(unique(this.go_id));
            
            % Compute number of satellite per epoch
            
            % considerig only epoch with code on the first frequency
            code_line = this.obs_code(:,1) == 'C' & this.f_id == 1;
            this.n_spe = sum(this.obs(code_line, :) ~= 0);
            % more generic approach but a lot slower
            %for e = 1 : this.length()
            %    this.n_spe(e) = numel(unique(this.go_id(this.obs(:,e) ~= 0)));
            %end
            
            this.active_ids = any(this.obs, 2);
            
            %this.sat.avail_index = false(this.time.length, this.parent.cc.getMaxNumSat());
        end
        
        function updateRinObsCode(this)
            % update the RINEX observation codes contained into the receiver
            % SYNTAX  this.updateRinObsCode()
            this.rin_obs_code = struct('G',[],'R',[],'E',[],'J',[],'C',[],'I',[],'S',[]);
            sys_c = this.getActiveSys();
            for ss = sys_c
                this.rin_obs_code.(ss) = serialize(this.getAvailableCode(ss)')';
            end
        end
        
        function updateTOT(this, obs, go_id)
            % SYNTAX
            %   this.updateTOT(time_rx, dt);
            %
            % INPUT
            %
            % OUTPUT
            %
            %   Update the signal time of travel based on range observations.
            % NOTE: to have satellite orbits at, 1mm sysncrnonization time of
            % travel has to be know with a precision of ~100m
            %    0.001m * (3 km/s  +         2 km/s)   /       300000 km/s   ~ 100m
            %              ^                 ^                    ^
            %
            %         (sat speed) (earth rot at sat orbit) (speed of light)
            if isempty(this.sat.tot)
                this.sat.tot = zeros(size(this.sat.avail_index));
            end
            if isempty(this.dt_ip) || ~any(this.dt_ip)
                this.sat.tot(:, go_id) =   nan2zero(zero2nan(obs)' / Core_Utils.V_LIGHT - this.dt(:, 1));  %<---- check dt with all the new dts field
            else
                this.sat.tot(:, go_id) =   nan2zero(zero2nan(obs)' / Core_Utils.V_LIGHT);  %<---- check dt with all the new dts field
            end
        end
        
        function updateAllTOT(this, synt_based)
            % upate time of travel for all satellites
            % for each receiver
            go_id = unique(this.go_id);
            for i = serialize(unique(this.go_id(this.obs_code(:,1) == 'C')))' % iterating only on sats with code observation
                
                sat_idx = (this.go_id == i) & (this.obs_code(:,1) == 'C');
                if nargin == 1 % obs based
                    c_obs = this.obs(sat_idx,:);
                    c_l_obs = colFirstNonZero(c_obs); % all best obs one each line %% CONSIDER USING ONLY 1 FREQUENCY FOR mm CONSISTENCY
                elseif synt_based % use the synteetc observation to get Time of flight
                    c_l_obs = this.getSyntObs(i);
                end
                %update time of flight times
                this.updateTOT(c_l_obs, i); % update time of travel
            end
        end
        
        function initAvailIndex(this, ep_ok)
            % initialize the avaliability index
            this.sat.avail_index = false(this.time.length, this.parent.cc.getMaxNumSat);
            this.updateAllAvailIndex();
            if nargin == 2
                if islogical(ep_ok)
                    this.sat.avail_index(~ep_ok,:) = false;
                else
                    this.sat.avail_index(setdiff(1 : size(this.sat.avail_index, 1), ep_ok), :) = false;
                end
            end
        end
        
        function updateAvailIndex(this, obs, go_gps)
            %  update avaliabilty of measurement on staellite
            this.sat.avail_index(:, go_gps) = obs > 0;
        end
        
        function updateAllAvailIndex(this)
            %  update avaliabilty of measurement on all
            % satellite based on all code and phase
            if isempty(this.sat.avail_index)
                this.sat.avail_index = false(this.time.length, this.parent.cc.getMaxNumSat);
            end
            for s = unique(this.go_id)'
                obs_idx = this.go_id == s & (this.obs_code(:,1) == 'C' | this.obs_code(:,1) == 'L');
                if sum(obs_idx) > 0
                    av_idx = colFirstNonZero(this.obs(obs_idx,:)) ~= 0 ;
                    this.sat.avail_index(:,s) = av_idx;
                end
            end
        end
        
        function setAvIdx2Visibility(this)
            % set the availability index to el >0
            this.sat.avail_index = true(this.time.length, this.parent.cc.getMaxNumSat);
            this.updateAzimuthElevation;
            this.sat.avail_index = this.sat.el > 0;
        end
    end
    
    % ==================================================================================================================================================
    %% METHODS CORRECTIONS
    % ==================================================================================================================================================
    %  FUNCTIONS TO COMPUTE APPLY AND REMOVE VARIOUS MODELED CORRECTIONS
    %  NOTE: Methods related to corrections that are applied to the observables and whose
    %  values is not stored separately (All except Iono and tropo) are
    %  structured as follow:
    %   - A : add or subtract the correction to the observations
    %   - applyA : a warpper of A to add the correction
    %   - remA : a wrapper of A to subtract the correction
    %   - computeA : does the numerical computation of A along the los
    %  where A is the name of the correction
    %  NOTE ON THE SIGN:
    %   Two type of corrections are presnts: real error on the range
    %   measuremnts and correction needed to bring the a changing position
    %   at the same coordinates. The first group will be subtracted from
    %   the observation the second one added. More specifically:
    %   "REAL" CORRECTIONS: (-)
    %   - Shapiro Delay
    %   - Phase wind up
    %   - PCV
    %   CHANGE OF COORDINATES (+)
    %   + PCO
    %   + Solid Earth tides
    %   + Ocean Loading
    %   + Pole tides
    %
    % ==================================================================================================================================================
    
    methods (Access = public)
        
        %--------------------------------------------------------
        % Time
        %--------------------------------------------------------
        
        function applyDtSat(this)
            if this.dts_delay_status == 0
                this.applyDtSatFlag(1);
                this.dts_delay_status = 1; %applied
            end
        end
        
        function remDtSat(this)
            if this.dts_delay_status == 1
                this.applyDtSatFlag(-1);
                this.dts_delay_status = 0; %applied
            end
        end
        
        function applyDtSatFlag(this,flag)
            % Apply clock satellite corrections for code and phase
            % IMPORTANT: if no clock is present delete the observation
            
            if isempty(this.active_ids)
                this.active_ids = false(size(this.obs,1),1);
            end
            this.initAvailIndex();
            % for each receiver
            [~, id] = unique(this.go_id);
            for i = id'
                go_id = this.go_id(i);
                sat_idx = (this.go_id == this.go_id(i)) & (this.obs_code(:,1) == 'C' | this.obs_code(:,1) == 'L');
                ep_idx = logical(sum(this.obs(sat_idx,:) ~= 0,1));
                dts_range = ( this.getDtS(go_id) + this.getRelClkCorr(go_id) ) * Core_Utils.V_LIGHT;
                for o = find(sat_idx)'
                    obs_idx_l = this.obs(o,:) ~= 0;
                    obs_idx = find(obs_idx_l);
                    dts_idx = obs_idx_l(ep_idx);
                    if ~isempty(dts_range(dts_idx))
                        if this.obs_code(o,1) == 'C'
                            this.obs(o, obs_idx_l) = this.obs(o,obs_idx_l) + sign(flag) * dts_range(dts_idx)';
                        else
                            this.obs(o, obs_idx_l) = this.obs(o,obs_idx_l) + sign(flag) * dts_range(dts_idx)'./this.wl(o);
                        end
                    end
                    dts_range_2 = dts_range(dts_idx);
                    nan_idx = obs_idx(isnan(dts_range_2));
                    this.obs(o, nan_idx) = 0;
                end
            end
        end
        
        function remDtPPP(this)
            % From the PPP a clock error from the phases have been estimated
            % -> remove it from the observations 
            %
            % Update dt_ip time to consider also this dt
            %
            % SYNTAX
            %   this.remDtPPP
            
            this.dt_ip = this.dt_ip + this.dt;
            this.smoothAndApplyDt();
        end
        
        function smoothAndApplyDt(this, smoothing_win, are_pr_jumping, are_ph_jumping)
            % Smooth dt * c correction computed from init-positioning with a spline with base 3 * rate,
            % apply the smoothed dt to pseudo-ranges and phases
            %
            % INPUT
            %   smoothing_win   moving window to smooth dt (spline base)
            %   are_pr_jumping   are the pr jumping?
            %   are_ph_jumping   are the pr jumping?
            %
            % SYNTAX
            %   this.smoothAndApplyDt(smoothing_win, is_pr_jumping, is_ph_jumping)
            if nargin == 1
                smoothing_win = 0; % do not smooth
            end
            if nargin < 4
                are_pr_jumping = false;
                are_ph_jumping = false;
            end                
            if any(smoothing_win)
                this.log.addMessage(this.log.indent('Smooth and apply the clock error of the receiver'));
            else
                this.log.addMessage(this.log.indent('Apply the clock error of the receiver'));
            end
            id_ko = this.dt == 0;
            lim = getOutliers(this.dt(:,1) ~= 0 & abs(Core_Utils.diffAndPred(this.dt(:,1),2)) < 1e-7);
            % lim = [lim(1) lim(end)];
            dt_w_border = [this.dt(1); zero2nan(this.dt(:,1)); this.dt(end,1)];
            dt_pr = simpleFill1D(dt_w_border, isnan(dt_w_border), 'pchip');
            dt_pr([1 end] ) = [];
            if smoothing_win(1) > 0
                for i = 1 : size(lim, 1)
                    if lim(i,2) - lim(i,1) > 5
                        dt_pr(lim(i,1) : lim(i,2)) = splinerMat([], dt_pr(lim(i,1) : lim(i,2)), smoothing_win(1));
                    end
                end
            end
            if length(smoothing_win) == 2
                dt_pr = splinerMat([], dt_pr, smoothing_win(2));
            end
            
            this.dt = simpleFill1D(zero2nan(dt_pr), id_ko, 'pchip');
            if (~are_ph_jumping)
                id_jump = abs(diff(dt_pr)) > 1e-4; %find clock resets
                ddt = simpleFill1D(diff(dt_pr), id_jump, 'linear');
                dt_ph = dt_pr(1) + [0; cumsum(ddt)];
            else
                dt_ph = dt_pr;
            end
            this.applyDtRec(dt_pr, dt_ph)
            %this.dt_pr = this.dt_pr + this.dt;
            %this.dt_ph = this.dt_ph + this.dt;
            this.dt(:)  = 0; %zeros(size(this.dt_pr));
        end
        
        function [dop] = computeKinDop(this)
            % compute the diluiton of precison for the 3 coordinate and 
            % SYNTAX
            %   [dop] = computeDop(this)
            %
            % INPUT
            %
            % OUTPUT
            dop_kin = zeros(5,5,this.length);
            [XS_loc] = this.getXSLoc();
            [mf] = this.getSlantMF();
            this.updateCoordinates();
            phi = this.lat;
            lam = this.lon;

            %rotation matrix from global to local reference system
            R = [-sin(lam) cos(lam) 0;
                -sin(phi)*cos(lam) -sin(phi)*sin(lam) cos(phi);
                +cos(phi)*cos(lam) +cos(phi)*sin(lam) sin(phi)];

            for i = 1 : this.length
                idx_s = mf(i,:) ~= 0 & ~isnan(XS_loc(i,:,1));
                e =  rowNormalize(permute(XS_loc(i,idx_s,:),[2 3 1]));
                t =  mf(i,idx_s)';
                A = [e ones(sum(idx_s),1) t];
                dop_kin(:,:,i) = inv(A'*A);
                % rotate to go enu
                dop_kin(1:3,1:3) = R*dop_kin(1:3,1:3)*R';
            end
            this.dop_kin = dop_kin;
        end
        
        function [dop] = computeTropoClockDop(this)
            % compute the diluiton of precison for tropo and clock only
            % SYNTAX
            %   [dop] = computeDop(this)
            %
            % INPUT
            %
            % OUTPUT
            dop_tdt = zeros(2,2,this.length);
            [XS_loc] = this.getXSLoc();
            [mf] = this.getSlantMF();
            this.updateCoordinates();
            for i = 1 : this.length
                idx_s = mf(i,:) ~= 0 & ~isnan(XS_loc(i,:,1));
                t =  mf(i,idx_s)';
                A = [ones(sum(idx_s),1) t];
                dop_tdt(:,:,i) = inv(A'*A);
            end
            this.dop_tdt = dop_tdt;
        end
        
        function [dop] = getDopDiag(this, par_idx)
            % get diagona element in the diagonal matrix
            % SYNTAX
            %   [dop] = getDopDiag(this, par_idx)
            %
            % INPUT
            %     par_idx: 1 = x, 2 = y, 3 = z, 4 = t, 5 = ztd
            %
            % OUTPUT
            if isempty(this.dop)
                this.computeDop();
            end
            dop = this.dop_kin(:,par_idx,par_idx);
            if numel(par_idx) == 1 || sum(par_idx) == 1
                dop = permute(dop,[3 2 1]);
            end
        end
        
         function [dop] = getDopClkTropoDiag(this, par_idx)
            % get diagona element in the diagonal matrix
            % SYNTAX
            %   [dop] = getDopDiag(this, par_idx)
            %
            % INPUT
            %     par_idx: 1 = t, 2 = ztd
            %
            % OUTPUT
            if isempty(this.dop)
                this.computeDop();
            end
            dop = this.dop_tdt(:,par_idx,par_idx);
            if numel(par_idx) == 1 || sum(par_idx) == 1
                dop = permute(dop,[3 2 1]);
            end
         end
        
        function correctPhJump(this)
            % remove huge jumps in phase
            %
            % SYNTAX
            % this.correctPhJump()
            [ph, wl, id_ph] = this.getPhases();
            ddt = nan2zero(median(zero2nan(diff(ph -this.getSyntPhases)), 2, 'omitnan'));
            ddt(abs(ddt) < 1e3) = 0;
            if any(ddt)
                % This is an adaptation, too big jump probably indicates a problem in the data      
                ddt(abs(ddt) > 1e10) = 0; % correction added for Japanese station 0731 day 01/01/2019
                dt_dj = cumsum([0; ddt(:)]);
                ph = bsxfun(@minus, ph, dt_dj);
                this.setPhases(ph, wl, id_ph);
            end            
            % this.timeShiftObs(dt_dj ./ Core_Utils.V_LIGHT, true);
        end
        
        function applyDtRec(this, dt_pr, dt_ph)
            % Apply dt * c correction to pseudo-ranges and phases
            % SYNTAX
            %   this.applyDtRec(dt)
            %   this.applyDtRec(dt_pr, dt_ph)
            
            narginchk(2,3);
            if nargin == 2
                dt_ph = dt_pr;
            end
            [pr, id_pr] = this.getPseudoRanges();
            pr = bsxfun(@minus, pr, dt_pr * 299792458);
            this.setPseudoRanges(pr, id_pr);
            [ph, wl, id_ph] = this.getPhases();
            ph = bsxfun(@minus, ph, dt_ph * 299792458);
            this.setPhases(ph, wl, id_ph);
            this.time.addSeconds( - dt_pr);
        end
        
        function applyPhaseShift(this)
            if this.ph_shift_status == 0
                this.log.addMarkedMessage('Applying phase shift');
                this.phaseShift(1);
                this.ph_shift_status = 1; %applied
            end
        end
        
        function removePhaseShift(this)
            if this.ph_shift_status == 1
                this.log.addMarkedMessage('Removing phase shift');
                this.phaseShift(-1);
                this.ph_shift_status = 0; %applied
            end
        end
        
        function phaseShift(this, sgn)
            for sys_c = unique( this.system)
                if isfield(this.ph_shift, sys_c)
                    for j = 1 : length(this.ph_shift.(sys_c))
                        if this.ph_shift.(sys_c)(j) ~= 0
                            ph_shift = this.ph_shift.(sys_c)(j);
                            obs_code = this.rin_obs_code.(sys_c)(((j-1)*3+1) : j*3);
                            [obs, idx] = this.getObs(obs_code, sys_c);
                            obs = obs + sgn * ph_shift;
                            this.obs(idx,:) = obs;
                            
                        end
                    end
                end
            end
            
        end
        
        function shiftToNominal(this, phase_only)
            %  translate receiver observations to nominal epochs
            if nargin < 2
                phase_only = false;
            end
            nominal_time = getNominalTime(this);
            tt = round((nominal_time - this.time) * 1e7) / 1e7; % Rounding for RINEX precision
            this.timeShiftObs(tt, phase_only)
        end
        
        function restoreDtError(this)
            % reapply the dt of the inti postionign into the observation and reshift the obesrvation to the desidered time
            this.applyDtRec(-this.dt_ip);
            nominal_time = getNominalTime(this);
            nominal_time.addSeconds(-this.desync);
            tt = round((nominal_time - this.time) * 1e7) / 1e7; % Rounding for RINEX precision
            if any(tt)
                this.timeShiftObs(tt)
            end
        end
        
        function timeShiftObs(this, seconds, phase_only)
            % translate observations at different epoch based on linear modeling of the satellite
            % copute the sat postion at the current epoch
            
            if nargin < 3
                phase_only = false;
            end
            XS = this.getXSLoc();
            
            if ~phase_only
                % translate the time
                this.time.addSeconds(seconds);
            end
            % compute the sat postion at epoch traslated
            XS_t = this.getXSLoc();
            % compute the correction
            range = sqrt(sum(XS.^2,3));
            range_t = sqrt(sum(XS_t.^2,3));
            
            d_range = range_t - range;
            % Correct phases
            obs_idx = this.obs_code(:,1) == 'L' ;
            this.obs(obs_idx,:) = nan2zero(zero2nan(this.obs(obs_idx,:)) + bsxfun(@rdivide, d_range(:,this.go_id(obs_idx))', this.wl(obs_idx)));
            if ~phase_only
                % Correct pseudo-ranges
                obs_idx = this.obs_code(:,1) == 'C';
                this.obs(obs_idx,:) = nan2zero(zero2nan(this.obs(obs_idx,:)) + d_range(:,this.go_id(obs_idx))');
            end
        end
        
        % ----- shift to nominal at transmission time
        function shiftObs(this, seconds, go_id)
            XS = this.getXSLoc(go_id);
            % translate the time
            this.time.addSeconds(seconds);
            % compute the sat postion at epoch traslated
            XS_t = this.getXSLoc(go_id);
            this.time.addSeconds(-seconds);
            range = sqrt(sum(XS.^2,2));
            range_t = sqrt(sum(XS_t.^2,2));
            idx_sat = this.sat.avail_index(:,go_id);
            % compuet earth rotation correction
            d_earth = zeros(size(XS,1),1);
            [XS_tx_r ,XS_tx] = this.getXSTxRot(go_id);
            XS_tx_r = XS_tx_r - repmat(this.xyz,sum(idx_sat),1);
            XS_tx = XS_tx - repmat(this.xyz,sum(idx_sat),1);
            range_e = sqrt(sum(XS_tx_r.^2,2));
            range_ne = sqrt(sum(XS_tx.^2,2));
            d_earth(idx_sat) = range_e - range_ne;
            d_range = nan2zero(range_t - range - d_earth);
            % Correct phases
            obs_idx = this.obs_code(:,1) == 'L' & this.go_id == go_id ;
            this.obs(obs_idx,:) = nan2zero(zero2nan(this.obs(obs_idx,:)) + bsxfun(@rdivide, repmat(d_range',sum(obs_idx),1), this.wl(obs_idx)));
            % Correct pseudo-ranges
            obs_idx = this.obs_code(:,1) == 'C'  & this.go_id == go_id;
            this.obs(obs_idx,:) = nan2zero(zero2nan(this.obs(obs_idx,:)) + repmat(d_range',sum(obs_idx),1));
            
        end
        
        function shiftToNominalTransmission(this)
            % tranlate the obseravtion accounting for each travel time
            % so all observations are trasmitted at nominal time
            
            %firstly shift to nominal
            this.shiftToNominal();
            % then shift each sta for its time of travel
            go_ids = unique(this.go_id);
            for g = go_ids'
                tot = this.sat.tot(:,g);
                this.shiftObs(tot, g);
                this.sat.tot(:,g) = 0;
            end
        end
        
        %--------------------------------------------------------
        % Group Delay
        %--------------------------------------------------------
        
        function applyGroupDelay(this)
            if this.group_delay_status == 0
                this.log.addMarkedMessage('Adding code group delays');
                this.groupDelay(1);
                this.group_delay_status = 1; %applied
            end
        end
        
        function remGroupDelay(this)
            if this.group_delay_status == 1
                this.log.addMarkedMessage('Removing code group delays');
                this.groupDelay(-1);
                this.group_delay_status = 0; %applied
            end
        end
        
        function groupDelay(this, sgn)
            % . apply group delay corrections for code and phase
            % measurement when a value if provided from an external source
            % (Navigational file  or DCB file)
            for i = 1 : size(this.sat.cs.group_delays, 2)
                sys  = this.sat.cs.group_delays_flags(i,1);
                code = this.sat.cs.group_delays_flags(i,2:4);
                f_num = str2double(code(2));
                idx = this.findObservableByFlag(code, sys);
                if sum(this.sat.cs.group_delays(:,i)) ~= 0
                    if ~isempty(idx)
                        for s = 1 : size(this.sat.cs.group_delays,1)
                            sat_idx = idx((this.prn(idx) == s));
                            full_ep_idx = not(abs(this.obs(sat_idx,:)) < 0.1);
                            if this.sat.cs.group_delays(s,i) ~= 0
                                this.obs(sat_idx,full_ep_idx) = this.obs(sat_idx,full_ep_idx) + sign(sgn) * this.sat.cs.group_delays(s,i);
                            elseif ~this.cc.isRefFrequency(sys, f_num)
                                this.active_ids(idx) = false;
                                idx = this.findObservableByFlag(['C' code(2:end)], sys);
                                this.active_ids(sat_idx) = sgn < 0;
                            end
                        end
                    end
                else
                    % mark as bad obs frequencies that are nor reference frequencies or that have no correction
                    if ~this.cc.isRefFrequency(sys, f_num)
                        idx = this.findObservableByFlag(['C' code(2:end)], sys);
                        this.active_ids(idx) = sgn < 0;
                    end
                end
            end
            
            id_ko = find(~this.active_ids);
            if ~isempty(id_ko)
                [prn_ko, id_sort] = sort(this.prn(id_ko));
                system_ko = this.system(id_ko(id_sort));
                obs_code_ko = this.obs_code(id_ko(id_sort),:);
                
                this.log.addWarning('No group delay found for some satellite / obs code')
                for s = unique(prn_ko)'
                    id = find(prn_ko == s);
                    this.log.addMessage(this.log.indent(sprintf(' - sat %c%02d missing group delay for obs code:%s', system_ko(id(1)), s, sprintf(' %c%c%c', obs_code_ko(id,: )'))));
                end
                
                this.log.addWarning('Enabling those observables without applying group delay\nSystematic biases might be present in the pseudo-ranges');
                
                % remove empty observables
                %this.remObs(id_ko);
                this.active_ids(id_ko) = true;
            end
        end
        
        %--------------------------------------------------------
        % Earth rotation parameters
        %--------------------------------------------------------
        
        function [XS_r] = earthRotationCorrection(this, XS, go_id)
            % SYNTAX
            %   [XS_r] = this.earthRotationCorrection(XS)
            %
            % INPUT
            %   XS      = positions of satellites
            %   time_rx = receiver time
            %   cc      = Constellation Collector
            %   sat     = satellite
            % OUTPUT
            %   XS_r    = Satellite postions rotated by earth roattion occured
            %   during time of travel
            %
            %   Rotate the satellites position by the earth rotation
            %   occured during time of travel of the signal
            
            %%% TBD -> consider the case XS and travel_time does not match
            XS_r = zeros(size(XS));
            
            idx = this.sat.avail_index(:,go_id) > 0;
            travel_time = this.sat.tot(idx,go_id);
            sys = this.getSysPrn(go_id);
            switch char(sys)
                case 'G'
                    omegae_dot = this.cc.gps.ORBITAL_P.OMEGAE_DOT;
                case 'R'
                    omegae_dot = this.cc.glo.ORBITAL_P.OMEGAE_DOT;
                case 'E'
                    omegae_dot = this.cc.gal.ORBITAL_P.OMEGAE_DOT;
                case 'C'
                    omegae_dot = this.cc.bds.ORBITAL_P.OMEGAE_DOT;
                case 'J'
                    omegae_dot = this.cc.qzs.ORBITAL_P.OMEGAE_DOT;
                case 'I'
                    omegae_dot = this.cc.irn.ORBITAL_P.OMEGAE_DOT;
                otherwise
                     Core.getLogger.addWarning('Something went wrong in Receiver_Work_Space.earthRotationCorrection() \nUnrecognized Satellite system!\n');
                    omegae_dot = this.cc.gps.ORBITAL_P.OMEGAE_DOT;
            end
            omega_tau = omegae_dot * travel_time;
            xR  = [cos(omega_tau)    sin(omega_tau)];
            yR  = [-sin(omega_tau)    cos(omega_tau)];
            XS_r(:,1) = sum(xR .* XS(:,1:2),2); % X
            XS_r(:,2) = sum(yR .* XS(:,1:2),2); % Y
            XS_r(:,3) = XS(:,3); % Z
        end
        
        %--------------------------------------------------------
        % Azimuth and Elevation
        %--------------------------------------------------------
        
        function updateAzimuthElevation(this, go_id)
            % Upadte azimute elevation into.sat
            % SYNTAX
            %   this.updateAzimuthElevation(<sat>)
            this.updateAllAvailIndex();
            if nargin < 2
                for i = unique(this.go_id)'
                    if sum(this.go_id == i) > 0
                        this.updateAzimuthElevation(i);
                    end
                end
            else
                if isempty(this.sat.el)
                    this.sat.el = zeros(this.length, this.cc.getMaxNumSat);
                end
                if isempty(this.sat.az)
                    this.sat.az = zeros(this.length, this.cc.getMaxNumSat);
                end
                if isempty(this.sat.avail_index)
                    this.sat.avail_index = true(this.length, this.parent.cc.getMaxNumSat);
                end
                av_idx = this.sat.avail_index(:, go_id) ~= 0;
                [this.sat.az(av_idx, go_id), this.sat.el(av_idx, go_id)] = this.computeAzimuthElevation(go_id);
            end
        end
        
        function [mf, el_points] = computeEmpMF(this, el_points, show_fig)
            % Compute an empirical hisotropic and homogeneous mapping function
            %
            % SYNTAX
            %   [mf, el_points] = this.computeEmpMF(<el_points>)
            %
            % EXAMPLE
            %   [mf, el_points] = this.computeEmpMF();
            
            if nargin < 3
                show_fig = false;
            end
            
            use_median = true;
            if use_median
                nppb = 1; % number of points per bin (1 degree)
            else
                nppb = 100; % number of points per bin (1 degree)
            end
            
            el = this.getEl;
            slant_td = bsxfun(@rdivide, this.getSlantTD, this.getZtd());
            
            % keep only valid data
            el = el(~isnan(zero2nan(slant_td)));
            slant_td = slant_td(~isnan(zero2nan(slant_td)));
            [el, id] = sort(el); slant_td = slant_td(id);
            if (nargin < 2) || isempty(el_points)
                el_points = max(0, (min(el(:)))) : 0.1 : min(90, (max(el(:))));
            end
            
            % Limit the number of points to use for spline interpolation (speedup)
            % 100 points per bin (1 degree) choosen randomly
            bin_size = hist(el, 0.5 : 0.1 : 90);
            bin_offset = [0; cumsum(bin_size(:))];
            id_ok = [];
            for b = 1 : numel(bin_size)
                if (bin_size(b) > nppb)
                    if use_median
                        bin_slant = slant_td(serialize(bin_offset(b) + (1 : bin_size(b))));
                        [~, id_tmp] = min(abs(bin_slant - median(bin_slant)));
                        id_ok = [id_ok; bin_offset(b) + id_tmp(1)];
                    else
                        id_tmp = serialize(bin_offset(b) + randperm(bin_size(b)));
                        id_ok = [id_ok; sort(id_tmp(1 : nppb))];
                    end
                else
                    id_ok = [id_ok; serialize(bin_offset(b) + (1 : bin_size(b)))];
                end
            end
            if show_fig
                figure;
                plot(el(:), slant_td(:), '.'); hold on;
                plot(el(id_ok), slant_td(id_ok), 'o');
            end
            % The mapping function at zenith is 1 => to best fit with spline I prefer to estimate
            % it with terminal value = 0
            el = el(id_ok);
            slant_td = slant_td(id_ok) - 1;
            zeinth_fill = (max(el): 0.01 : 90)';
            el = [el; zeinth_fill];
            slant_td = [slant_td; zeros(size(zeinth_fill))];
            
            [~, ~, ~, mf] = splinerMat(el, slant_td, 1, 0, el_points); % Spline base 10 degrees
            mf = mf + 1; % readding the removed bias
            if show_fig
                plot(el_points, mf, '.','MarkerSize', 10);
            end
        end
        
        function [az, el] = computeAzimuthElevation(this, go_id)
            % Force computation of azimuth and elevation
            %
            % SYNTAX
            %   [az, el] = this.computeAzimuthElevation(go_id)
            if (nargin < 2) || isempty(go_id)
                go_id = unique(this.go_id);
            end
            XS = this.getXSTxRot(go_id);
            [az, el] = this.computeAzimuthElevationXS(XS);
        end
        
        function [az, el] = computeAzimuthElevationXS(this, XS, XR)
            % SYNTAX
            %   [az, el] = this.computeAzimuthElevationXS(XS)
            %
            % INPUT
            % XS = positions of satellite [n_epoch x 1]
            % XR = positions of reciever [n_epoch x 1] (optional, non static
            % case)
            % OUTPUT
            % Az = Azimuths of satellite [n_epoch x 1]
            % El = Elevations of satellite [n_epoch x 1]
            % during time of travel
            %
            %   Compute Azimuth and elevation of the staellite
            n_epoch = size(XS,1);
            if nargin > 2
                if size(XR,1) ~= n_epoch
                    this.log.addError('[ computeAzimuthElevationXS ] Number of satellite positions differ from number of receiver positions');
                    return
                end
            else
                XR = repmat(this.xyz(1,:),n_epoch,1);
            end
            
            az = zeros(n_epoch,1); el = zeros(n_epoch,1);
            
            [phi, lam] = cart2geod(XR(:,1), XR(:,2), XR(:,3));
            XSR = XS - XR; %%% sats orbit with origin in receiver
            
            e_unit = [-sin(lam)            cos(lam)           zeros(size(lam))       ]; % East unit vector
            n_unit = [-sin(phi).*cos(lam) -sin(phi).*sin(lam) cos(phi)]; % North unit vector
            u_unit = [ cos(phi).*cos(lam)  cos(phi).*sin(lam) sin(phi)]; % Up unit vector
            
            e = sum(e_unit .* XSR,2);
            n = sum(n_unit .* XSR,2);
            u = sum(u_unit .* XSR,2);
            
            hor_dist = sqrt( e.^2 + n.^2);
            
            zero_idx = hor_dist < 1.e-20;
            
            az(zero_idx) = 0;
            el(zero_idx) = 90;
            
            az(~zero_idx) = atan2d(e(~zero_idx), n(~zero_idx));
            el(~zero_idx) = atan2d(u(~zero_idx), hor_dist(~zero_idx));
        end
        
        %--------------------------------------------------------
        % Iono and Tropo
        % -------------------------------------------------------
        
        function updateErrTropo(this, go_id)
            %INPUT
            % sat : number of sat
            % flag: flag of the tropo model
            % update the tropospheric correction
            
            atmo = Core.getAtmosphere();
            
            if isempty(this.sat.err_tropo)
                this.sat.err_tropo = zeros(size(this.sat.avail_index));
            end
            
            if nargin < 2 || strcmp(go_id, 'all')
                this.log.addMessage(this.log.indent('Updating tropospheric errors'))
                
                go_id = unique(this.go_id)';
            end
            this.sat.err_tropo(:, go_id) = 0;
            
            %%% compute lat lon
            [~, ~, h_full] = this.getMedianPosGeodetic();
            if abs(h_full) > 1e4
                this.log.addWarning('Height out of reasonable value for terrestrial postioning skipping tropo update')
                return
            end
            % get meteo data
            
            % upadte the ztd zwd
            this.updateAprTropo();
            
            zwd = nan2zero(this.getZwd);
            apr_zhd = this.getAprZhd;
            cotel = zero2nan(cotd(this.sat.el(this.id_sync, :)));
            cosaz = zero2nan(cosd(this.sat.az(this.id_sync, :)));
            sinaz = zero2nan(sind(this.sat.az(this.id_sync, :)));
            [gn ,ge] = this.getGradient();
            [mfh, mfw] = this.getSlantMF();
            if any(ge(:))
                for g = go_id
                    this.sat.err_tropo(this.id_sync,g) = mfh(:,g) .* apr_zhd + mfw(:,g).*zwd;
                end
            else
                for g = go_id
                    this.sat.err_tropo(this.id_sync,g) = mfh(:,g) .* apr_zhd + mfw(:,g) .* zwd + gn .* mfw(:,g) .* cotel(:,g) .* cosaz(:,g) + ge .* mfw(:,g) .* cotel(:,g) .* sinaz(:,g);
                end
            end
        end
        
        function reset2AprioriTropo(this)
            % reset the ztd to the apriori values
            %
            % SYNTAX: this.reset2AprioriTropo()
            
            this.zwd(:) = 0;
            this.updateErrTropo();
        end
        
        
        function updateAmbIdx(this)
            % get matrix of same dimesion of the observation showing the ambiguity index of the obsarvation and save them into this.sat.amb_idx
            %
            % SYNTAX:
            % this.updateAmbIdx()
            
            amb_idx = ones(size(this.sat.cicle_slip_ph_by_ph));
            n_epochs = size(amb_idx,1);
            n_stream = size(amb_idx,2);
            for s = 1:n_stream
                if s > 1
                    amb_idx(:, s) = amb_idx(:, s) + amb_idx(n_epochs, s-1);
                end
                cs = find(this.sat.cicle_slip_ph_by_ph(:, s) > 0)';
                for c = cs
                    amb_idx(c:end, s) = amb_idx(c:end, s) + 1;
                end
            end
            amb_idx = zero2nan(amb_idx .* (this.getPhases ~= 0));
            amb_idx = Core_Utils.remEmptyAmbIdx(amb_idx);
            this.sat.amb_idx      = amb_idx;
            this.sat.amb_val      = nan(max(max(amb_idx)),1);
            this.sat.is_amb_fixed = false(max(max(amb_idx)),1);
        end
        
        
        function updateErrIono(this, go_id, iono_model_override)
            if isempty(this.sat.err_iono)
                this.sat.err_iono = zeros(size(this.sat.avail_index));
            end
            
            this.log.addMessage(this.log.indent('Updating ionospheric errors'))
            if nargin < 2
                go_id  = 1 : this.parent.cc.getMaxNumSat();
            end
            
            if nargin < 3
                iono_model_override = this.state.getIonoModel;
            end
            atmo = Core.getAtmosphere();
            if iono_model_override == 3 && isempty(atmo.ionex.data) && ~isempty(this.sat.cs.iono) && sum(sum(this.sat.cs.iono~=0)) > 0
                this.log.addWarning('No ionex file present switching to Klobuckar');
                iono_model_override = 2;
            end
            if iono_model_override == 3 && isempty(atmo.ionex.data) && (isempty(this.sat.cs.iono) || sum(sum(this.sat.cs.iono~=0)) > 0)
                this.log.addError('No iono model present');
                iono_model_override = 1;
            end
            this.updateCoordinates();
            switch iono_model_override
                case 1 % no model
                    this.sat.err_iono(:, go_id) = 0;
                case 2 % Klobuchar model
                    if ~isempty(this.sat.cs.iono)
                        for s = go_id(:)'
                            idx = this.sat.avail_index(:,s);
                            [week, sow] = time2weektow(this.time.getSubSet(idx).getGpsTime());
                            this.sat.err_iono(idx,s) = Atmosphere.klobucharModel(this.lat, this.lon, this.sat.az(idx,s), this.sat.el(idx,s), sow, this.sat.cs.iono);
                        end
                    else
                        this.log.addWarning('No klobuchar parameter found, iono correction not computed');
                    end
                case 3 % IONEX
                    this.sat.err_iono = atmo.getFOIdelayCoeff(this.lat, this.lon, this.sat.az, this.sat.el, this.h_ellips, this.time);
            end
        end
        
        function applyIonoModel(this)
            if this.iono_status == 0
                this.log.addMarkedMessage('Applying Ionosphere model');
                this.ionoModel(1);
                this.iono_status = 1; % applied
            end
        end
        
        function remIonoModel(this)
            if this.iono_status == 1
                this.log.addMarkedMessage('Removing Ionosphere model');
                this.ionoModel(-1);
                this.iono_status = 0; % not applied
            end
        end
        
        function ionoModel(this, sign)
            % Apply the selected iono model
            %
            % SYNTAX
            %   this.applyIonoModel()
            ph_obs = this.obs_code(:,1) == 'L';
            pr_obs = this.obs_code(:,1) == 'C';
            for i = 1 : size(this.sat.err_iono,2)
                idx_sat = this.go_id == i & (ph_obs | pr_obs);
                if sum(idx_sat) > 0
                    for s = find(idx_sat)'
                        iono_delay = this.sat.err_iono(:,i) * this.wl(s).^2;
                        if ph_obs(s) > 0
                            this.obs(s,:) = nan2zero(zero2nan(this.obs(s,:)) + sign * (iono_delay') ./ this.wl(s));
                        else
                            this.obs(s,:) = nan2zero(zero2nan(this.obs(s,:)) - sign * (iono_delay'));
                        end
                    end
                end
            end
        end
        
        %--------------------------------------------------------
        % Solid earth tide
        % -------------------------------------------------------
        
        function solidEarthTide(this,sgn)
            %  add or subtract ocean loading from observations
            et_corr = this.computeSolidTideCorr();
            
            for s = 1 : this.parent.cc.getMaxNumSat()
                obs_idx = this.obs_code(:,1) == 'C' |  this.obs_code(:,1) == 'L';
                obs_idx = obs_idx & this.go_id == s;
                if sum(obs_idx) > 0
                    for o = find(obs_idx)'
                        o_idx = this.obs(o, :) ~=0; %find where apply corrections
                        if  this.obs_code(o,1) == 'L'
                            this.obs(o,o_idx) = this.obs(o,o_idx) + sign(sgn)* et_corr(o_idx,s)' ./ this.wl(o);
                        else
                            this.obs(o,o_idx) = this.obs(o,o_idx) + sign(sgn)* et_corr(o_idx,s)';
                        end
                    end
                end
            end
        end
        
        function applySolidEarthTide(this)
            if this.et_delay_status == 0 && this.state.isSolidEarth
                this.log.addMarkedMessage('Applying Solid Earth Tide corrections');
                this.solidEarthTide(1);
                this.et_delay_status = 1; %applied
            end
        end
        
        function remSolidEarthTide(this)
            if this.et_delay_status == 1
                this.log.addMarkedMessage('Removing Solid Earth Tide corrections');
                this.solidEarthTide(-1);
                this.et_delay_status = 0; %not applied
            end
        end
        
        function solid_earth_corr = computeSolidTideCorr(this, sat)
            
            % SYNTAX
            %   [stidecorr] = this.getSolidTideCorr();
            %
            % INPUT
            %
            % OUTPUT
            %   stidecorr = solid Earth tide correction terms (along the satellite-receiver line-of-sight)
            %
            %
            %   Computation of the solid Earth tide displacement terms.
            if nargin < 2
                sat  = 1 : this.parent.cc.getMaxNumSat();
            end
            solid_earth_corr = zeros(this.time.length, length(sat));
            XR = this.getXR();
            
            [~, lam, ~, phiC] = cart2geod(XR(1,1), XR(1,2), XR(1,3));
            %north (b) and radial (c) local unit vectors
            b = [-sin(phiC)*cos(lam); -sin(phiC)*sin(lam); cos(phiC)];
            c = [+cos(phiC)*cos(lam); +cos(phiC)*sin(lam); sin(phiC)];
            
            %interpolate sun moon and satellites
            time = this.time.getCopy;
            [X_sun, X_moon]  = this.sat.cs.sunMoonInterpolate(time);
            XS               = this.sat.cs.coordInterpolate(time, sat);
            %receiver geocentric position
            
            
            XR_u = rowNormalize(XR);
            
            %sun geocentric position
            X_sun_n = repmat(sqrt(sum(X_sun.^2,2)),1,3);
            X_sun_u = X_sun ./ X_sun_n;
            
            %moon geocentric position
            X_moon_n = repmat(sqrt(sum(X_moon.^2,2)),1,3);
            X_moon_u = X_moon ./ X_moon_n;
            
            %latitude dependence
            p = (3*sin(phiC)^2-1)/2;
            
            %gravitational parameters
            GE = Galileo_SS.ORBITAL_P.GM; %Earth
            GS = GE*332946.0; %Sun
            GM = GE*0.01230002; %Moon
            
            %Earth equatorial radius
            R = 6378136.6;
            
            %nominal degree 2 Love number
            H2 = 0.6078 - 0.0006*p;
            %nominal degree 2 Shida number
            L2 = 0.0847 + 0.0002*p;
            
            %solid Earth tide displacement (degree 2)
            Vsun  = repmat(sum(conj(X_sun_u) .* XR_u, 2),1,3);
            Vmoon = repmat(sum(conj(X_moon_u) .* XR_u, 2),1,3);
            r_sun2  = (GS*R^4)./(GE*X_sun_n.^3) .*(H2.*XR_u.*(1.5*Vsun.^2  - 0.5)+ 3*L2*Vsun .*(X_sun_u  - Vsun .*XR_u));
            r_moon2 = (GM*R^4)./(GE*X_moon_n.^3).*(H2.*XR_u.*(1.5*Vmoon.^2 - 0.5) + 3*L2*Vmoon.*(X_moon_u - Vmoon.*XR_u));
            r = r_sun2 + r_moon2;
            
            %nominal degree 3 Love number
            H3 = 0.292;
            %nominal degree 3 Shida number
            L3 = 0.015;
            
            %solid Earth tide displacement (degree 3)
            r_sun3  = (GS.*R^5)./(GE.*X_sun_n.^4) .*(H3*XR_u.*(2.5.*Vsun.^3  - 1.5.*Vsun)  +   L3*(7.5*Vsun.^2  - 1.5).*(X_sun_u  - Vsun .*XR_u));
            r_moon3 = (GM.*R^5)./(GE.*X_moon_n.^4).*(H3*XR_u.*(2.5.*Vmoon.^3 - 1.5.*Vmoon) +   L3*(7.5*Vmoon.^2 - 1.5).*(X_moon_u - Vmoon.*XR_u));
            r = r + r_sun3 + r_moon3;
            
            %from "conventional tide free" to "mean tide"
            radial = (-0.1206 + 0.0001*p)*p;
            north  = (-0.0252 + 0.0001*p)*sin(2*phiC);
            r = r;% + repmat([radial*c + north*b]',time.length,1);
            
            %displacement along the receiver-satellite line-of-sight
            [XS] = this.getXSLoc();
            for i  = 1 : length(sat)
                s = sat(i);
                sat_idx = this.sat.avail_index(:,s) ~= 0;
                XSs = permute(XS(sat_idx,s,:),[1 3 2]);
                LOSu = rowNormalize(XSs);
                solid_earth_corr(sat_idx,i) = sum(conj(r(sat_idx,:)).*LOSu,2);
            end
            
        end
        
        function updateSolidEarthCorr(this, sat)
            % upadte the correction related to solid earth
            % solid tides, ocean loading, pole tides.
            if isempty(this.sat.solid_earth_corr)
                this.log.addMessage(this.log.indent('Updating solid earth corrections'))
                this.sat.solid_earth_corr = zeros(size(this.sat.avail_index));
            end
            if nargin < 2
                this.sat.solid_earth_corr = this.computeSolidTideCorr();
                %                 for s = 1 : size(this.sat.avail_index,2)
                %                     this.updateSolidEarthCorr(s);
                %                 end
            else
                this.sat.solid_earth_corr(:,sat) = this.computeSolidTideCorr(sat);% + this.computeOceanLoading(sat) + this.getPoleTideCorr(sat);
            end
        end
        
        %--------------------------------------------------------
        % Ocean Loading
        % -------------------------------------------------------
        
        function oceanLoading(this, sgn)
            %  add or subtract ocean loading from observations
            ol_corr = this.computeOceanLoading();
            if isempty(ol_corr)
                this.log.addWarning('No ocean loading displacements matrix present for the receiver')
                return
            end
            
            for s = 1 : this.parent.cc.getMaxNumSat()
                obs_idx = this.obs_code(:,1) == 'C' |  this.obs_code(:,1) == 'L';
                obs_idx = obs_idx & this.go_id == s;
                if sum(obs_idx) > 0
                    for o = find(obs_idx)'
                        o_idx = this.obs(o, :) ~=0; %find where apply corrections
                        if  this.obs_code(o,1) == 'L'
                            this.obs(o,o_idx) = this.obs(o,o_idx) + sign(sgn)* ol_corr(o_idx,s)' ./ this.wl(o);
                        else
                            this.obs(o,o_idx) = this.obs(o,o_idx) + sign(sgn)* ol_corr(o_idx,s)';
                        end
                    end
                end
            end
        end
        
        function applyOceanLoading(this)
            if this.ol_delay_status == 0 && this.state.isOceanLoading
                this.log.addMarkedMessage('Applying Ocean Loading corrections');
                this.oceanLoading(1);
                this.ol_delay_status = 1; %applied
            end
        end
        
        function remOceanLoading(this)
            if this.ol_delay_status == 1
                this.log.addMarkedMessage('Removing Ocean Loading corrections');
                this.oceanLoading(-1);
                this.ol_delay_status = 0; %not applied
            end
        end
        
        
        
        function [ocean_load_corr] = computeOceanLoading(this, sat) % WARNING: to be tested
            
            % SYNTAX
            %   [oceanloadcorr] = ocean_loading_correction(time, XR, XS);
            %
            % INPUT
            %
            % OUTPUT
            %   oceanloadcorr = ocean loading correction terms (along the satellite-receiver line-of-sight)
            %
            %
            %   Computation of the ocean loading displacement terms.
            % NOTES:
            %  Inefficent to compute them separate by staellites always call
            %  as a block
            
            if nargin < 2
                sat = 1 : this.parent.cc.getMaxNumSat();
            end
            
            
            ocean_load_corr = zeros(this.time.length, length(sat));
            if isempty(this.ocean_load_disp)
                this.importOceanLoading();
            end
            if isempty(this.ocean_load_disp) || ((~isstruct(this.ocean_load_disp) && this.ocean_load_disp == -1) || this.ocean_load_disp.available == 0)
                return
            end
            
            ol_disp = this.ocean_load_disp;
            if false
                %terms depending on the longitude of the lunar node (see Kouba and Heroux, 2001)
                fj = 1; %(at 1-3 mm precision)
                uj = 0; %(at 1-3 mm precision)
                
                %ref: http://202.127.29.4/cddisa/data_base/IERS/Convensions/Convension_2003/SUBROUTINES/ARG.f
                tidal_waves = [1.40519E-4, 2.0,-2.0, 0.0, 0.00; ... % M2  - semidiurnal
                    1.45444E-4, 0.0, 0.0, 0.0, 0.00; ... % S2  - semidiurnal
                    1.37880E-4, 2.0,-3.0, 1.0, 0.00; ... % N2  - semidiurnal
                    1.45842E-4, 2.0, 0.0, 0.0, 0.00; ... % K2  - semidiurnal
                    0.72921E-4, 1.0, 0.0, 0.0, 0.25; ... % K1  - diurnal
                    0.67598E-4, 1.0,-2.0, 0.0,-0.25; ... % O1  - diurnal
                    0.72523E-4,-1.0, 0.0, 0.0,-0.25; ... % P1  - diurnal
                    0.64959E-4, 1.0,-3.0, 1.0,-0.25; ... % Q1  - diurnal
                    0.53234E-5, 0.0, 2.0, 0.0, 0.00; ... % Mf  - long-period
                    0.26392E-5, 0.0, 1.0,-1.0, 0.00; ... % Mm  - long-period
                    0.03982E-5, 2.0, 0.0, 0.0, 0.00];    % Ssa - long-period
                
                refdate = datenum([1975 1 1 0 0 0]);
                
                [week, sow] = time2weektow(this.time.getGpsTime);
                dateUTC = datevec(gps2utc(datenum(gps2date(week, sow))));
                
                %separate the fractional part of day in seconds
                fday = dateUTC(:,4)*3600 + dateUTC(:,5)*60 + dateUTC(:,6);
                dateUTC(:,4:end) = 0;
                
                %number of days since reference date (1 Jan 1975)
                days = (datenum(dateUTC) - refdate);
                
                capt = (27392.500528 + 1.000000035*days)/36525;
                
                %mean longitude of the Sun at the beginning of day
                H0 = (279.69668 + (36000.768930485 + 3.03e-4.*capt).*capt).*pi/180;
                
                %mean longitude of the Moon at the beginning of day
                S0 = (((1.9e-6*capt - 0.001133).*capt + 481267.88314137).*capt + 270.434358).*pi/180;
                
                %mean longitude of the lunar perigee at the beginning of day
                P0 = (((-1.2e-5.*capt - 0.010325).*capt + 4069.0340329577).*capt + 334.329653)*pi/180;
                
                corr = zeros(this.time.length,3);
                corrENU = zeros(this.time.length,3);
                for k = 1 : 11
                    angle = tidal_waves(k,1)*fday + tidal_waves(k,2)*H0 + tidal_waves(k,3)*S0 + tidal_waves(k,4)*P0 + tidal_waves(k,5)*2*pi;
                    corr  = corr + repmat(fj*ol_disp.matrix(1:3,k)',this.time.length,1).*cos(repmat(angle,1,3) + uj - repmat(ol_disp.matrix(4:6,k)'*pi/180,this.time.length,1));
                end
            else
                % all 342 tides
                corr = MOT_Generator.computeDisplacement(ol_disp.matrix(1:3,:), ol_disp.matrix(4:6,:), this.time);
            end
            corrENU(:,1) = -corr(:,2); %east
            corrENU(:,2) = -corr(:,3); %north
            corrENU(:,3) =  corr(:,1); %up
            
            % get XR
            XR = this.getXR();
            %displacement along the receiver-satellite line-of-sight
            XRcorr = local2globalPos(corrENU', XR')';
            corrXYZ = XRcorr - XR;
            %displacement along the receiver-satellite line-of-sight
            [XS] = this.getXSLoc();
            for i  = 1 : length(sat)
                s = sat(i);
                sat_idx = this.sat.avail_index(:,s);
                XSs = permute(XS(sat_idx,s,:),[1 3 2]);
                LOSu = rowNormalize(XSs);
                ocean_load_corr(sat_idx,i) = sum(conj(corrXYZ(sat_idx,:)).*LOSu,2);
            end
        end
        
        %--------------------------------------------------------
        % Pole Tide
        % -------------------------------------------------------
        
        function poleTide(this,sgn)
            %  add or subtract ocean loading from observations
            pt_corr = this.computePoleTideCorr();
            if isempty(pt_corr)
                this.log.addWarning('No ocean loading displacements matrix present for the receiver')
                return
            end
            
            for s = 1 : this.parent.cc.getMaxNumSat()
                obs_idx = this.obs_code(:,1) == 'C' |  this.obs_code(:,1) == 'L';
                obs_idx = obs_idx & this.go_id == s;
                if sum(obs_idx) > 0
                    for o = find(obs_idx)'
                        o_idx = this.obs(o, :) ~=0; %find where apply corrections
                        if  this.obs_code(o,1) == 'L'
                            this.obs(o,o_idx) = this.obs(o,o_idx) + sign(sgn)* pt_corr(o_idx,s)' ./ this.wl(o);
                        else
                            this.obs(o,o_idx) = this.obs(o,o_idx) + sign(sgn)* pt_corr(o_idx,s)';
                        end
                    end
                end
            end
        end
        
        function applyPoleTide(this)
            if this.pt_delay_status == 0 && this.state.isPoleTide
                this.log.addMarkedMessage('Applying Pole Tide corrections');
                this.poleTide(1);
                this.pt_delay_status = 1; %applied
            end
        end
        
        function remPoleTide(this)
            if this.pt_delay_status == 1
                this.log.addMarkedMessage('Removing Pole Tide corrections');
                this.poleTide(-1);
                this.pt_delay_status = 0; %not applied
            end
        end
        
        function [pole_tide_corr] = computePoleTideCorr(this, sat)
            
            % SYNTAX
            %   [poletidecorr] = pole_tide_correction(time, XR, XS, SP3, phiC, lam);
            %
            % INPUT
            %
            % OUTPUT
            %   poletidecorr = pole tide correction terms (along the satellite-receiver line-of-sight)
            %
            %
            %   Computation of the pole tide displacement terms.
            
            if nargin < 2
                sat = 1 : this.parent.cc.getMaxNumSat();
            end
            
            XR = this.getXR;
            [~, lam, ~, phiC] = cart2geod(XR(1,1), XR(2,1), XR(3,1));
            
            pole_tide_corr = zeros(this.time.length,length(sat));
            erp  = this.sat.cs.erp;
            %interpolate the pole displacements
            if (~isempty(erp))
                if (length(erp.t) > 1)
                    m1 = interp1(erp.t, erp.m1, this.time.getGpsTime, 'linear', 'extrap');
                    m2 = interp1(erp.t, erp.m2, this.time.getGpsTime, 'linear', 'extrap');
                else
                    m1 = repmat(erp.m1,this.time.length,1);
                    m2 = repmat(erp.m2,this.time.length,1);
                end
                
                deltaR   = -33*sin(2*phiC).*(m1.*cos(lam) + m2.*sin(lam))*1e-3;
                deltaLam =  9* cos(  phiC).*(m1.*sin(lam) - m2.*cos(lam))*1e-3;
                deltaPhi = -9* cos(2*phiC).*(m1.*cos(lam) + m2.*sin(lam))*1e-3;
                
                corrENU(:,1) = deltaLam; %east
                corrENU(:,2) = deltaPhi; %north
                corrENU(:,3) = deltaR;   %up
                
                %displacement along the receiver-satellite line-of-sight
                XRcorr = local2globalPos(corrENU', XR')';
                corrXYZ = XRcorr - XR;
                [XS] = this.getXSLoc();
                for i  = 1 : length(sat)
                    s = sat(i);
                    sat_idx = this.sat.avail_index(:,s);
                    XSs = permute(XS(sat_idx,s,:),[1 3 2]);
                    LOSu = rowNormalize(XSs);
                    pole_tide_corr(sat_idx,i) = sum(conj(corrXYZ(sat_idx,:)).*LOSu,2);
                end
            end
            
        end
        
        %--------------------------------------------------------
        % High Order Ionospheric effect + bending
        % -------------------------------------------------------
        
        function HOI(this,sgn)
            %  add or subtract ocean loading from observations
            [hoi2, hoi3, bending] = this.computeHOI();
            
            for s = 1 : this.parent.cc.getMaxNumSat()
                obs_idx = this.obs_code(:,1) == 'C' |  this.obs_code(:,1) == 'L';
                obs_idx = obs_idx & this.go_id == s;
                if sum(obs_idx) > 0
                    for o = find(obs_idx)'
                        o_idx = this.obs(o, :) ~=0; %find where apply corrections
                        wl = this.wl(o);
                        wl3 = wl^3;
                        wl4 = wl^4;
                        if  this.obs_code(o,1) == 'L'
                            this.obs(o,o_idx) = this.obs(o,o_idx) - sign(sgn)*( -1/2 *hoi2(o_idx,s)'*wl3  - 1/3* hoi3(o_idx,s)'*wl4 +  bending(o_idx,s)'*wl4) ./ this.wl(o);
                        else
                            this.obs(o,o_idx) = this.obs(o,o_idx) - sign(sgn)*( hoi2(o_idx,s)'*wl3 + hoi3(o_idx,s)'*wl4 + bending(o_idx,s)'*wl4);
                        end
                    end
                end
            end
        end
        
        function applyHOI(this)
            if this.hoi_delay_status == 0 && this.state.isHOI
                this.log.addMarkedMessage('Applying High Order Ionospheric Effect');
                if this.state.isIonoBroadcast()
                    this.log.addWarning('Ionosphere parameters from broadcast do not allow HOI computation (yet)\nplease use IONEX files');
                else
                    this.HOI(1);
                    this.hoi_delay_status = 1; %applied
                end
            end
        end
        
        function remHOI(this)
            if this.hoi_delay_status == 1
                this.log.addMarkedMessage('Removing High Order Ionospheric Effect');
                this.HOI(-1);
                this.hoi_delay_status = 0; %not applied
            end
        end
        
        function [hoi_delay2_coeff, hoi_delay3_coeff, bending_coeff] =  computeHOI(this)
            
            % SYNTAX
            %
            % INPUT
            %
            % OUTPUT
            %
            %
            %
            %   Computation of thigh order ionospheric effect
            
            this.updateCoordinates();
            atmo = Core.getAtmosphere();
            [hoi_delay2_coeff, hoi_delay3_coeff, bending_coeff] = atmo.getHOIdelayCoeff(this.lat,this.lon, this.sat.az,this.sat.el,this.h_ellips,this.time);
            
        end
        
        %--------------------------------------------------------
        % Atmospheric loading
        % -------------------------------------------------------
        
        function atmLoad(this,sgn)
            %  add or subtract ocean loading from observations
            al_corr = this.computeAtmLoading();
            if isempty(al_corr)
                this.log.addWarning('No ocean loading displacements matrix present for the receiver')
                return
            end
            
            for s = 1 : this.parent.cc.getMaxNumSat()
                obs_idx = this.obs_code(:,1) == 'C' |  this.obs_code(:,1) == 'L';
                obs_idx = obs_idx & this.go_id == s;
                if sum(obs_idx) > 0
                    for o = find(obs_idx)'
                        o_idx = this.obs(o, :) ~=0; %find where apply corrections
                        if  this.obs_code(o,1) == 'L'
                            this.obs(o,o_idx) = this.obs(o,o_idx) + sign(sgn)* al_corr(o_idx,s)' ./ this.wl(o);
                        else
                            this.obs(o,o_idx) = this.obs(o,o_idx) + sign(sgn)* al_corr(o_idx,s)';
                        end
                    end
                end
            end
        end
        
        function applyAtmLoad(this)
            if this.atm_load_delay_status == 0  && this.state.isAtmLoading
                this.log.addMarkedMessage('Applying atmospheric loading effect');
                this.atmLoad(1);
                this.atm_load_delay_status = 1; %applied
            end
        end
        
        function remAtmLoad(this)
            if this.atm_load_delay_status == 1
                this.log.addMarkedMessage('Removing atmospheric loading effect');
                this.atmLoad(-1);
                this.atm_load_delay_status = 0; %not applied
            end
        end
        
        function [al_corr] =  computeAtmLoading(this, sat)
            
            % SYNTAX
            %
            % INPUT
            %
            % OUTPUT
            %
            %
            %
            %   Computation of atmopsheric loading
            
            if nargin < 2
                sat = 1 : this.parent.cc.getMaxNumSat();
            end
            this.updateCoordinates();
            atmo = Core.getAtmosphere();
            dsa = this.time.first.getCopy();
            dso = this.time.getSubSet(this.time.length).getCopy();
            dso.addSeconds(6*3600);
            fname = this.state.getNTAtmLoadFileName( dsa, dso);
            for i = 1 : length(fname)
                atmo.importAtmLoadCoeffFile(fname{i});
            end
            [corrXYZ] = atmo.getAtmLoadCorr(this.lat,this.lon,this.h_ellips, this.time);
            [XS] = this.getXSLoc();
            for i  = 1 : length(sat)
                s = sat(i);
                sat_idx = this.sat.avail_index(:,s);
                XSs = permute(XS(sat_idx,s,:),[1 3 2]);
                LOSu = rowNormalize(XSs);
                al_corr(sat_idx,i) = sum(conj(corrXYZ(sat_idx,:)).*LOSu,2);
            end
            
        end
        
        %--------------------------------------------------------
        % Phase Wind up
        % -------------------------------------------------------
        
        function phaseWindUpCorr(this,sgn)
            %  add or subtract ocean loading from observations
            ph_wind_up = this.computePhaseWindUp();
            
            for s = 1 : this.parent.cc.getMaxNumSat()
                obs_idx = this.obs_code(:,1) == 'L';
                obs_idx = obs_idx & this.go_id == s;
                if sum(obs_idx) > 0
                    for o = find(obs_idx)'
                        o_idx = this.obs(o, :) ~=0; %find where apply corrections
                        this.obs(o,o_idx) = this.obs(o,o_idx) - sign(sgn)* ph_wind_up(o_idx,s)'; % add or subtract???
                    end
                end
            end
        end
        
        function applyPhaseWindUpCorr(this)
            if this.pw_delay_status == 0 && this.state.isPhaseWind
                this.log.addMarkedMessage('Applying Phase Wind Up corrections');
                this.phaseWindUpCorr(1);
                this.pw_delay_status = 1; %applied
            end
        end
        
        function remPhaseWindUpCorr(this)
            if this.pw_delay_status == 1
                this.log.addMarkedMessage('Removing Phase Wind Up corrections');
                this.phaseWindUpCorr(-1);
                this.pw_delay_status = 0; %not applied
            end
        end
        
        function [ph_wind_up] = computePhaseWindUp(this)
            
            %east (a) and north (b) local unit vectors
            XR = this.getXR();
            [phi, lam] = cart2geod(XR(:,1), XR(:,2), XR(:,3));
            a = [-sin(lam) cos(lam) zeros(size(lam))];
            b = [-sin(phi).*cos(lam) -sin(phi).*sin(lam) cos(phi)];
            s_time = this.time.getCopy();%SubSet(av_idx);
            s_a = a;%(av_idx,:);
            s_b = b;%(av_idx,:);
            
            
            sat = 1: this.parent.cc.getMaxNumSat();
            
            [x, y, z] = this.sat.cs.getSatFixFrame(s_time);
            ph_wind_up = zeros(this.time.length,length(sat));
            for s = sat
                av_idx = this.sat.avail_index(:,s);
                i_s = squeeze(x(:,s,:));
                j_s = squeeze(y(:,s,:));
                k_s = squeeze(z(:,s,:));
                
                %receiver and satellites effective dipole vectors
                Dr = s_a - k_s.*repmat(sum(k_s.*s_a,2),1,3) + cross(k_s,s_b);
                Ds = i_s - k_s.*repmat(sum(k_s.*i_s,2),1,3) - cross(k_s,j_s);
                
                %phase wind-up computation
                psi = sum(conj(k_s) .* cross(Ds, Dr),2);
                arg = sum(conj(Ds) .* Dr,2) ./ (sqrt(sum(Ds.^2,2)) .* sqrt(sum(Dr.^2,2)));
                arg(arg < -1) = -1;
                arg(arg > 1) = 1;
                dPhi = sign(psi).*acos(arg)./(2*pi);
                % find jump
                ddPhi = diff(dPhi);
                jumps = find(abs(ddPhi) > 0.9);
                jumps_sgn = sign(ddPhi(jumps));
                for t = 1 : length(jumps)
                    jump = jumps(t);
                    dPhi((jump+1):end) = dPhi((jump+1):end) - jumps_sgn(t);
                end
                ph_wind_up(av_idx,s) = dPhi(av_idx);
            end
        end
        
        %--------------------------------------------------------
        % Shapiro Delay
        % -------------------------------------------------------
        
        function shDelay(this,sgn)
            %  add or subtract shapiro delay from observations
            for s = 1 : this.parent.cc.getMaxNumSat()
                obs_idx = this.obs_code(:,1) == 'C' |  this.obs_code(:,1) == 'L';
                obs_idx = obs_idx & this.go_id == s;
                if sum(obs_idx) > 0
                    freqs = unique(str2num(this.obs_code(obs_idx,2)));
                    freqs = reshape(freqs,1,length(freqs));
                    for f = freqs
                        obs_idx_f = obs_idx & this.obs_code(:,2) == num2str(f);
                        sh_delays = this.computeShapirodelay(s);
                        for o = find(obs_idx_f)'
                            pcv_idx = this.obs(o, this.sat.avail_index(:, s)) ~=0; %find which correction to apply
                            if sum(pcv_idx) >0
                                o_idx = this.obs(o, :) ~=0; %find where apply corrections
                                if  this.obs_code(o,1) == 'L'
                                    this.obs(o,o_idx) = this.obs(o,o_idx) - sign(sgn)* sh_delays(pcv_idx)' ./ this.wl(o);
                                else
                                    this.obs(o,o_idx) = this.obs(o,o_idx) - sign(sgn)* sh_delays(pcv_idx)';
                                end
                            end
                        end
                    end
                end
            end
        end
        
        function applyShDelay(this)
            if this.sh_delay_status == 0 && this.state.isShapiro
                this.log.addMarkedMessage('Applying Shapiro delay corrections');
                this.shDelay(1);
                this.sh_delay_status = 1; %applied
            end
        end
        
        function remShDelay(this)
            if this.sh_delay_status == 1
                this.log.addMarkedMessage('Removing Shapiro delay corrections');
                this.shDelay(-1);
                this.sh_delay_status = 0; %not applied
            end
        end
        
        function [sh_delay] = computeShapirodelay(this, sat)
            % SYNTAX
            %   [corr, distSR_corr] = this.getRelDistance(XS, XR);
            %
            % INPUT
            % XS = positions of satellite [n_epoch x 1]
            % XR = positions of reciever [n_epoch x 1] (optional, non static
            % case)
            %
            % OUTPUT
            %   corr = relativistic range error correction term (Shapiro delay)
            %   dist = dist
            %
            %   Compute distance from satellite ot reciever considering
            %   (Shapiro delay) - copied from
            %   relativistic_range_error_correction.m
            XS = this.getXSTxRot(sat);
            if this.isStatic()
                XR = repmat(this.xyz,size(XS,1),1);
            else
                XR = this.xyz(this.sat.avail_index(:,sat),:);
            end
            
            distR = sqrt(sum(XR.^2 ,2));
            distS = sqrt(sum(XS.^2 ,2));
            
            distSR = sqrt(sum((XS-XR).^2 ,2));
            
            
            GM = 3.986005e14;
            
            %corr = 2*GM/(Core_Utils.V_LIGHT^2) * log((distR + distS + distSR)./(distR + distS - distSR)); %#ok<CPROPLC>
            
            sh_delay = 2*GM/(Core_Utils.V_LIGHT^2) * log((distR + distS + distSR)./(distR + distS - distSR));
            
        end
        
        %--------------------------------------------------------
        % PCV
        % -------------------------------------------------------
        
        function applyremPCV(this, sgn)
            %  correct measurement for PCV both of receiver
            % antenna and satellite antenna
            if ~isempty(this.pcv) || ~isempty(this.sat.cs.ant_pcv)
                % this.updateAllAvailIndex(); % not needed?
                % getting sat - receiver vector for each epoch
                XR_sat = - this.getXSLoc();
                
                % Receiver PCV correction
                if ~isempty(this.pcv) && ~isempty(this.pcv.name) && this.state.isRecPCV()
                    f_code_history = []; % save f_code checked to print only one time the warning message
                    for s = unique(this.go_id)'
                        sat_idx = this.sat.avail_index(:, s);
                        el = this.sat.el(sat_idx, s);
                        az = this.sat.az(sat_idx, s);
                        neu_los = [cosd(az).*cosd(el) sind(az).*cosd(el) sind(el)];
                        obs_idx = this.obs_code(:,1) == 'C' |  this.obs_code(:,1) == 'L';
                        obs_idx = obs_idx & this.go_id == s;
                        if sum(obs_idx) > 0 && (this.pcv.n_frequency > 0)
                            freqs = unique(str2num(this.obs_code(obs_idx,2)));
                            for f = freqs'
                                obs_idx_f = obs_idx & this.obs_code(:,2) == num2str(f);
                                sys = this.system(obs_idx_f);
                                f_code = [sys(1) sprintf('%02d',f)];
                                
                                [pco, pco_idx] = this.getPCO(f,sys(1));
                                if ~isempty(pco)
                                    
                                    pco_delays = neu_los * (pco + [fliplr(this.parent.ant_delta_en) this.parent.ant_delta_h]');
                                    pcv_delays = pco_delays - this.getPCV(pco_idx, el, az);
                                    for o = find(obs_idx_f)'
                                        pcv_idx = this.obs(o, this.sat.avail_index(:, s)) ~= 0; % find which correction to apply
                                        o_idx = this.obs(o, :) ~= 0; % find where apply corrections
                                        if  this.obs_code(o, 1) == 'L'
                                            this.obs(o,o_idx) = this.obs(o,o_idx) + sign(sgn) * pcv_delays(pcv_idx)' ./ this.wl(o);
                                        else
                                            this.obs(o,o_idx) = this.obs(o,o_idx) + sign(sgn) * pcv_delays(pcv_idx)';
                                        end
                                    end
                                else
                                    if isempty(f_code_history) || ~sum(strLineMatch(f_code_history, f_code))
                                        this.log.addMessage(this.log.indent(sprintf('No corrections found for antenna model %s on frequency %s',this.parent.ant_type, f_code)));
                                        f_code_history = [f_code_history;f_code];
                                    end
                                end
                            end
                        end
                    end
                end
                
                % Satellite PCV correction
                if ~isempty(this.sat.cs.ant_pcv)
                    % getting satellite reference frame for each epoch
                    [x, y, z] = this.sat.cs.getSatFixFrame(this.time);
                    sat_ok = unique(this.go_id)';
                    % transform into satellite reference system
                    XR_sat(:, sat_ok, :) = cat(3,sum(XR_sat(:, sat_ok, :) .* x(:, sat_ok, :),3), sum(XR_sat(:, sat_ok, :) .* y(:, sat_ok, :), 3), sum(XR_sat(:, sat_ok, :) .* z(:, sat_ok, :), 3));
                    
                    % getting az and el
                    distances = sqrt(sum(XR_sat.^2,3));
                    XR_sat_norm = XR_sat ./ repmat(distances, 1, 1, 3);
                    
                    az = atan2(XR_sat_norm(:, :, 2), XR_sat_norm(:, :, 1)); % here azimuth is intended as angle from x axis
                    az(az<0) = az(az<0) + 2*pi;
                    el = atan2(XR_sat_norm(:, :, 3), sqrt(sum(XR_sat_norm(:, :, 1:2).^2, 3)));
                    
                    % getting pscv and applying it to the obs
                    for s = unique(this.go_id)'
                        obs_idx = this.obs_code(:,1) == 'C' |  this.obs_code(:,1) == 'L';
                        obs_idx = obs_idx & this.go_id == s;
                        if sum(obs_idx) > 0
                            freqs = str2num(unique(this.obs_code(obs_idx,2)));
                            for f = freqs'
                                obs_idx_f = obs_idx & this.obs_code(:,2) == num2str(f);
                                az_idx = ~isnan(az(:,s));
                                az_tmp = az(az_idx,s) / pi * 180;
                                el_idx = ~isnan(el(:,s));
                                el_tmp = el(el_idx,s) / pi * 180;
                                ant_id = this.getAntennaId(s);
                                pcv_delays = this.sat.cs.getPCV( f, ant_id, el_tmp, az_tmp);
                                for o = find(obs_idx_f)'
                                    pcv_idx = this.obs(o, az_idx) ~= 0; %find which correction to apply
                                    if sum(pcv_idx) > 0
                                        o_idx = this.obs(o, :) ~=0 & az_idx'; %find where apply corrections
                                        if  this.obs_code(o,1) == 'L'
                                            this.obs(o,o_idx) = this.obs(o,o_idx) + sign(sgn) * pcv_delays(pcv_idx)' ./ this.wl(o); % is it a plus
                                        else
                                            this.obs(o,o_idx) = this.obs(o,o_idx) + sign(sgn) * pcv_delays(pcv_idx)';
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                end
            end
        end
        
        function pcv_delay = getPCV(this, idx, el, az, method)
            % get the pcv correction for a given satellite and a given
            % azimuth and elevations using linear or bilinear interpolation
            
            if (nargin < 5)
                method = 'minterp';
            end
            pcv_delay = zeros(size(el));
            
            pcv = this.pcv;
            
            % transform el in zen
            zen = 90 - el;
            % get el idx
            zen_pcv = pcv.tablePCV_zen;
            
            min_zen = zen_pcv(1);
            max_zen = zen_pcv(end);
            d_zen = (max_zen - min_zen)/(length(zen_pcv)-1);
            zen_float = (zen - min_zen)/d_zen + 1;
            if nargin < 4 || isempty(pcv.tablePCV_azi) % no azimuth change
                pcv_val = pcv.tableNOAZI(:,:,idx); % extract the right frequency
                %pcv_delay = d_f_r_el .* pcv_val(zen_idx)' + (1 - d_f_r_el) .* pcv_val(zen_idx + 1)';
                
                % Use polynomial interpolation to smooth PCV
                pcv_delay = Core_Utils.interp1LS(1 : numel(pcv_val), pcv_val, min(8,numel(pcv_val)), zen_float);
            else
                % find azimuth indexes
                az_pcv = pcv.tablePCV_azi;
                min_az = az_pcv(1);
                max_az = az_pcv(end);
                d_az = (max_az - min_az)/(length(az_pcv)-1);
                az_float = (mod(az, 360) - min_az)/d_az;
                az_idx = min(max(floor((mod(az,360) - min_az)/d_az) + 1, 1),length(az_pcv) - 1);
                d_f_r_az = min(max(mod(az, 360) - (az_idx-1)*d_az, 0)/d_az, 1);
                
                
                if strcmp(method, 'polyLS')
                    % Polynomial interpolation in elevation and griddedInterpolant in az
                    % filter PCV values in elevetion - slower
                    %%
                    pcv_val = pcv.tablePCV(:,:,idx); % extract the right frequency
                    step = 0.25;
                    zen_interp = (((floor(min(zen)/step)*step) : step : (ceil(max(zen)/step)*step))' - min_zen)/d_zen + 1;
                    
                    % Interpolate with a 7th degree polinomial in elevation
                    pcv_val = Core_Utils.interp1LS(1 : numel(pcv_val), pcv_val', min(8,size(pcv_val, 2)), zen_interp);
                    
                    n_az = size(pcv_val, 2);
                    b_dx = (n_az - floor(n_az / 3)) : (n_az - 1); % dx border
                    b_sx = 2 : (n_az - floor(n_az / 3));          % sx border
                    % replicate border for azimuth periodicity
                    pcv_val = [pcv_val(:, b_dx), pcv_val, pcv_val(:, b_sx)];
                    az_val = [az_pcv(b_dx) - 360, az_pcv, az_pcv(b_sx) + 360];
                    
                    % Using scattered interpolant for azimuth to have a smooth interpolation
                    [zen_m, az_m] = ndgrid(zen_interp, az_val);
                    fun = griddedInterpolant(zen_m, az_m, pcv_val);
                    pcv_delay = fun(zen_float, mod(az, 360));
                elseif strcmp(method, 'minterp')
                    % Interpolation with griddedInterpolant
                    % leinear interpolation - faster
                    pcv_val = pcv.tablePCV(:,:,idx)'; % extract the right frequency
                    
                    n_az = size(pcv_val, 2);
                    b_dx = (n_az - floor(n_az / 3)) : (n_az - 1); % dx border
                    b_sx = 2 : (n_az - floor(n_az / 3));          % sx border
                    % replicate border for azimuth periodicity
                    pcv_val = [pcv_val(:, b_dx), pcv_val, pcv_val(:, b_sx)];
                    az_val = [az_pcv(b_dx) - 360, az_pcv, az_pcv(b_sx) + 360];
                    
                    % Using scattered interpolant for azimuth to have a smooth interpolation
                    [zen_m, az_m] = ndgrid(zen_pcv, az_val);
                    fun = griddedInterpolant(zen_m, az_m, pcv_val, 'linear');
                    pcv_delay = fun(zen, az);
                elseif strcmp(method, 'lin')
                    
                    % linear interpolation between consecutive values
                    % bad performance
                    %%
                    zen_idx = min(max(floor((zen - min_zen)/d_zen) + 1 , 1),length(zen_pcv) - 1);
                    d_f_r_el = min(max(zen_idx*d_zen - zen, 0)/ d_zen, 1) ;
                    pcv_val = pcv.tablePCV(:,:,idx); % extract the right frequency
                    %interpolate along zenital angle
                    idx1 = sub2ind(size(pcv_val),az_idx,zen_idx);
                    idx2 = sub2ind(size(pcv_val),az_idx,zen_idx+1);
                    pcv_delay_lf =  d_f_r_el .* pcv_val(idx1) + (1 - d_f_r_el) .* pcv_val(idx2);
                    idx1 = sub2ind(size(pcv_val),az_idx+1,zen_idx);
                    idx2 = sub2ind(size(pcv_val),az_idx+1,zen_idx+1);
                    pcv_delay1_rg = d_f_r_el .* pcv_val(idx1) + (1 - d_f_r_el) .* pcv_val(idx2);
                    %interpolate alogn azimtuh
                    pcv_delay = d_f_r_az .* pcv_delay_lf + (1 - d_f_r_az) .* pcv_delay1_rg;
                end
            end
        end
        
        
        function [pco, pco_idx] = getPCO(this, freq, sys)
            % get pco
            if ~isempty(this.pcv)
                f_code = [sys sprintf('%02d',freq)];
                pco_idx = strLineMatch(this.pcv.frequency_name, f_code);
                if sum(pco_idx)
                    pco = this.pcv.offset(:, :, pco_idx)';
                else
                    % find closer gps frequency
                    gps_idx_l = this.pcv.frequency_name(:,1) == 'G';
                    gps_idx = find(gps_idx_l);
                    aval_frq = char(this.pcv.frequency_name(gps_idx,3));
                    fr_gps = zeros(size(aval_frq));
                    for i = 1 : length(aval_frq)
                        ava_frq_idx = this.cc.getGPS.CODE_RIN3_2BAND == aval_frq(i);
                        fr_gps(i) = this.cc.getGPS.F_VEC(ava_frq_idx);
                    end
                    trg_frq_idx = this.cc.getSys(sys).CODE_RIN3_2BAND == num2str(freq);
                    fr_trg = this.cc.getSys(sys).F_VEC(trg_frq_idx);
                    [~,idx_near] = min(abs(fr_gps-fr_trg));
                    pco = this.pcv.offset(:, :, gps_idx(idx_near))';
                    this.log.addMessage(this.log.indent(sprintf('No corrections found for antenna model %s on frequency %s, usign %s instead',this.parent.ant_type, f_code,this.pcv.frequency_name(gps_idx(idx_near),:))));
                    pco_idx(gps_idx(idx_near)) = true;
                end
            else
                pco = [];
            end
        end
        
        function applyPCV(this)
            if (this.pcv_delay_status == 0) && this.state.isRecPCV
                this.log.addMarkedMessage('Applying PCV corrections');
                this.applyremPCV(1);
                this.pcv_delay_status = 1; % applied
            end
        end
        
        function remPCV(this)
            if this.pcv_delay_status == 1
                this.log.addMarkedMessage('Removing PCV corrections');
                this.applyremPCV(-1);
                this.pcv_delay_status = 0; % applied
            end
        end
        
        %--------------------------------------------------------
        % All
        %--------------------------------------------------------
        
        function remAllCorrections(this)
            % rem all the corrections
            % SYNTAX
            %   this.remAllCorrections();
            if ~this.isEmpty()
                this.remDtSat();
                this.remGroupDelay();
                this.remPCV();
                this.remPoleTide();
                this.remPhaseWindUpCorr();
                this.remSolidEarthTide();
                this.remShDelay();
                this.remOceanLoading();
                this.remHOI();
                this.remAtmLoad();
            else
                this.iono_status = false;
                this.group_delay_status = false;
                this.dts_delay_status = false;
                this.sh_delay_status = false;
                this.pcv_delay_status = false;
                this.ol_delay_status = false;
                this.pt_delay_status = false;
                this.pw_delay_status = false;
                this.et_delay_status = false;
                this.hoi_delay_status = false;
                this.atm_load_delay_status = false;
            end
        end
        
        function applyAllCorrections(this)
            % Apply all the corrections
            % SYNTAX
            %   this.applyAllCorrections();
            this.applyDtSat();
            this.applyGroupDelay();
            this.applyPCV();
            this.applyPoleTide();
            this.applyPhaseWindUpCorr();
            this.applySolidEarthTide();
            this.applyShDelay();
            this.applyOceanLoading();
            this.applyHOI();
            this.applyAtmload();
        end
    end
    
    
    % ==================================================================================================================================================
    %% METHODS PROCESSING
    % ==================================================================================================================================================
    
    methods
        function [is_pr_jumping, is_ph_jumping] = correctTimeDesync(this, disable_dt_correction)
            %   Correction of jumps in code and phase due to dtR and time de-sync
            % SYNTAX
            %   this.correctTimeDesync()
            this.log.addMarkedMessage('Correct for time desync');
            if nargin < 2 | isempty(disable_dt_correction)
                disable_dt_correction = true; % Skip to speed-up processing
            end
            
            % computing nominal_time
            nominal_time_zero = floor(this.time.first.getMatlabTime() * 24)/24; % start of day
            rinex_time = this.time.getRefTime(nominal_time_zero); % seconds from start of day
            nominal_time = round(rinex_time / this.time.getRate) * this.time.getRate;
            ref_time = (nominal_time(1) : this.time.getRate : nominal_time(end))';
            
            % reordering observations filling empty epochs with zeros;
            this.time = GPS_Time(nominal_time_zero, ref_time, this.time.isGPS(), 2);
            this.time.toUnixTime;
            
            [~, id_not_empty] = intersect(ref_time, nominal_time);
            id_empty = setdiff(1 : numel(nominal_time), id_not_empty);
            
            time_desync = nan(size(nominal_time));
            time_desync(id_not_empty) = round((rinex_time - nominal_time) * 1e7) / 1e7; % the rinex time has a maximum of 7 significant decimal digits
            time_desync = simpleFill1D(time_desync,isnan(time_desync),'nearest');
            
            this.desync = time_desync;
            clear nominal_time_zero nominal_time rinex_time
            
            this.obs(:, id_not_empty) = this.obs;
            this.obs(:, id_empty) = 0;
            this.n_spe(id_not_empty) = this.n_spe;
            this.n_spe(id_empty) = 0;
            
            % extract observations
            [ph, wl, id_ph] = this.getPhases();
            [pr, id_pr] = this.getPseudoRanges();
            
            dt_ph = zeros(this.time.length, 1);
            dt_pr = zeros(this.time.length, 1);
            
            [ph_dj, dt_ph_dj, is_ph_jumping] = Core_PP.remDtJumps(ph);
            [pr_dj, dt_pr_dj, is_pr_jumping] = Core_PP.remDtJumps(pr);
            % apply desync
            if ~disable_dt_correction
                if any(time_desync)
                    if (numel(dt_ph_dj) > 1 && numel(dt_pr_dj) > 1)
                        id_ko = flagExpand(sum(~isnan(ph), 2) == 0, 1);
                        tmp = diff(dt_pr_dj); tmp(~id_ko) = 0; tmp = cumsum(tmp);
                        dt_ph_dj = dt_ph_dj + tmp; % use jmp estimation from pseudo-ranges
                    end
                    
                    ddt_pr = Core_Utils.diffAndPred(dt_pr_dj);
                    
                    if (max(abs(time_desync)) > 1e-4)
                        % time_desync is a introduced by the receiver to maintain the drift of the clock into a certain range
                        time_desync = simpleFill1D(time_desync, all(isnan(pr), 2), 'nearest');
                        ddt = [0; diff(time_desync)];
                        ddrifting_pr = ddt - ddt_pr;
                        % drifting_pr = cumsum(ddrifting_pr);
                        drifting_pr = time_desync - dt_pr_dj;
                        
                        % Linear interpolation of ddrifting
                        jmp_reset = find(abs(ddt_pr) > 1e-7); % points where the clock is reset
                        lim = getOutliers(any(~isnan(ph),2));
                        lim = [lim(1); lim(end)];
                        jmp_fit = setdiff([find(abs(ddrifting_pr) > 1e-7); lim(:)], jmp_reset); % points where desync interpolate the clock
                        jmp_fit(jmp_fit==numel(drifting_pr)) = [];
                        jmp_fit(jmp_fit==1) = [];
                        d_points_pr = [drifting_pr(jmp_reset); drifting_pr(jmp_fit) - ddrifting_pr(jmp_fit)/2];
                        jmp = [jmp_reset; jmp_fit];
                        if numel(d_points_pr) < 3
                            drifting_pr = zeros(size(drifting_pr));
                        else
                            %lim = interp1(jmp, d_points_pr, [1 numel(drifting_pr)]', 'linear', 'extrap');
                            %drifting_pr = interp1([1; jmp; numel(drifting_pr)], [lim(1); d_points_pr; lim(2)], 'pchip');
                            drifting_pr = interp1(jmp, d_points_pr, (1 : numel(drifting_pr))', 'pchip');
                        end
                        
                        dt_ph_dj = iif(is_pr_jumping == is_ph_jumping, dt_pr_dj, dt_ph_dj);
                        dt_ph = drifting_pr + dt_ph_dj;
                        %dt_ph = drifting_pr * double(numel(dt_ph_dj) <= 1) + detrend(drifting_pr) * double(numel(dt_ph_dj) > 1) + dt_ph_dj;
                        dt_pr = drifting_pr + dt_pr_dj;
                        if ~isempty(jmp)
                            t_offset = round(mean(dt_pr(jmp) - time_desync(jmp) + ddrifting_pr(jmp)/2) * 1e7) * 1e-7;
                            dt_ph = dt_ph - t_offset;
                            dt_pr = dt_pr - t_offset;
                        end
                    else
                        dt_ph = dt_ph_dj;
                        dt_pr = dt_pr_dj;
                    end
                    
                else
                    if (is_ph_jumping ~= is_pr_jumping)
                        % epochs with no phases cannot estimate dt jumps
                        if (numel(dt_ph_dj) > 1 && numel(dt_pr_dj) > 1)
                            id_ko = flagExpand(sum(~isnan(ph), 2) == 0, 1);
                            tmp = diff(dt_pr_dj); tmp(~id_ko) = 0; tmp = cumsum(tmp);
                            dt_ph_dj = dt_ph_dj + tmp; % use jmp estimation from pseudo-ranges
                        end
                        
                        ddt_pr = Core_Utils.diffAndPred(dt_pr_dj);
                        jmp_reset = find(abs(ddt_pr) > 1e-7); % points where the clock is reset
                        jmp_reset(jmp_reset==numel(dt_pr_dj)) = [];
                        if numel(jmp_reset) > 2
                            drifting_pr = interp1(jmp_reset, dt_pr_dj(jmp_reset), (1 : numel(dt_pr_dj))', 'pchip');
                        else
                            drifting_pr = 0;
                        end
                        
                        dt_pr = dt_pr_dj - drifting_pr;
                        t_offset = mean(dt_pr);
                        dt_ph = dt_ph_dj - drifting_pr - t_offset;
                        dt_pr = dt_pr - t_offset;
                    end
                end
                
                if any(dt_ph_dj)
                    this.log.addMessage(this.log.indent('Correcting carrier phases jumps'));
                else
                    this.log.addMessage(this.log.indent('Correcting carrier phases for a dt drift estimated from desync interpolation'));
                end
                if any(dt_pr_dj)
                    this.log.addMessage(this.log.indent('Correcting pseudo-ranges jumps'));
                else
                    this.log.addMessage(this.log.indent('Correcting pseudo-ranges for a dt drift estimated from desync interpolation'));
                end
            end
            
            ph = bsxfun(@minus, ph, dt_ph .* 299792458);
            pr = bsxfun(@minus, pr, dt_pr .* 299792458);
            
            % Saving dt into the object properties
            this.dt_ph = dt_ph; %#ok<PROP>
            this.dt_pr = dt_pr; %#ok<PROP>
            
            % Outlier rejection
            if (this.state.isOutlierRejectionOn())
                this.log.addMarkedMessage('Removing main outliers');
                [ph, flag_ph] = Core_PP.flagRawObsD4(ph, ref_time - dt_ph, ref_time, 6, 5); % The minimum threshold (5 - the last parameter) is needed for low cost receiver that are applying dt corrections to the data - e.g. UBX8
                [pr, flag_pr] = Core_PP.flagRawObsD4(pr, ref_time - dt_pr, ref_time, 6, 5); % The minimum threshold (5 - the last parameter) is needed for low cost receiver that are applying dt corrections to the data - e.g. UBX8
            end
            
            % Saving observations into the object properties
            this.setPhases(ph, wl, id_ph);
            this.setPseudoRanges(pr, id_pr);
            
            this.time.addSeconds(time_desync - this.dt_pr);
        end
        
        function s0 = initPositioning(this, sys_c)
            % run the most appropriate init prositioning step depending on the static flag
            % calls initStaticPositioning() or initDynamicPositioning()
            % SYNTAX
            %   this.initPositioning();
            % INPUT
            %   sys_c = wanted system
            % Init "errors"
            if this.isEmpty()
                this.log.addError('Init positioning failed: the receiver object is empty');
            else
                this.log.addMarkedMessage('Computing position and clock errors using a code only solution')
                this.sat.err_tropo = zeros(this.time.length, this.parent.cc.getMaxNumSat());
                this.sat.tot = zeros(this.time.length, this.parent.cc.getMaxNumSat());
                this.sat.err_iono  = zeros(this.time.length, this.parent.cc.getMaxNumSat());
                this.sat.az  = zeros(this.time.length, this.parent.cc.getMaxNumSat());
                this.sat.el  = zeros(this.time.length, this.parent.cc.getMaxNumSat());
                this.sat.solid_earth_corr  = zeros(this.time.length, this.parent.cc.getMaxNumSat());
                this.log.addMessage(this.log.indent('Applying satellites Differential Code Biases (DCB)'))
                % if not applied apply group delay
                this.applyGroupDelay();
                this.log.addMessage(this.log.indent('Applying satellites clock errors and eccentricity dependent relativistic correction'))
                this.applyDtSat();
                % if
                %this.parent.static = 0;
                if this.isStatic()
                    %this.initStaticPositioningOld(obs, prn, sys, flag)
                    s0 = this.initStaticPositioning();
                else
                    s0 = this.initDynamicPositioning();
                end
            end
        end
        
        function s0 = initStaticPositioning(this)
            % SYNTAX
            %   this.StaticPositioning(obs, prn, sys, flag)
            %
            % INPUT
            % obs : observations [meters]
            % prn : prn of observations
            % sys : sys of observations
            % flag : name of observation [obs_code1 obs_code2 comb_code]
            %        comb_code --> Iono Free = I
            % OUTPUTt_glo11.
            %
            %
            %   Get positioning using code observables
            
            
            if this.isEmpty()
                this.log.addError('Static positioning failed: the receiver object is empty');
            else
                if isempty(this.id_sync)
                    this.id_sync = 1 : this.time.length;
                end
                % check if the epochs are present
                % getting the observation set that is going to be used in
                % setUPSA
                obs_set = Observation_Set();
                if this.isMultiFreq() %% case multi frequency
                    for sys_c = this.cc.sys_c
                        obs_set.merge(this.getPrefIonoFree('C', sys_c));
                    end
                else
                    for sys_c = this.cc.sys_c
                        f = this.getFreqs(sys_c);
                        if ~isempty(f)
                            obs_set.merge(this.getPrefObsSetCh(['C' num2str(f(1))], sys_c));
                        end
                    end
                end
                
                if sum(this.hasAPriori) == 0 %%% if no apriori information on the position
                    s0 = coarsePositioning(this, obs_set);
                else
                    s0 = 5;
                end
                
                if s0 > 0
                    this.updateAllAvailIndex();
                    this.updateAllTOT();
                    this.updateAzimuthElevation()
                    this.updateErrTropo();
                    if ~this.isMultiFreq()
                        this.updateErrIono();
                    end
                    this.log.addMessage(this.log.indent('Improving estimation'))
                                        
                    this.codeStaticPositioning(this.id_sync, this.state.cut_off);
                    %                 %----- NEXUS DEBUG
                    %                 this.adjustPrAmbiguity();
                    %                 this.codeStaticPositioning(this.id_sync, 15);
                    %------
                    this.remBadTracking();
                    
                    this.updateAllTOT();
                    this.log.addMessage(this.log.indent('Final estimation'))
                    corr = 2000;
                    i = 1;
                    while max(abs(corr)) > 0.1 && i < 3
                        rw_loops = 0; % number of re-weight loops
                        [corr, s0] = this.codeStaticPositioning(this.id_sync, this.state.cut_off, rw_loops); % no reweight
                        % final estimation of time of flight
                        this.updateAllAvailIndex()
                        this.updateAllTOT();
                        i = i+1;
                    end
                    this.log.addMessage(this.log.indent(sprintf('Estimation sigma0 %.3f m', s0) ))
                end                
            end
        end
        
        function s0 = coarsePositioning(this, obs_set)
            % get a very coarse postioning for the receiver
            if nargin < 2
                obs_set = Observation_Set();
                if this.isMultiFreq() %% case multi frequency
                    for sys_c = this.cc.sys_c
                        obs_set.merge(this.getPrefIonoFree('C', sys_c));
                    end
                else
                    for sys_c = this.cc.sys_c
                        f = this.getFreqs(sys_c);
                        obs_set.merge(this.getPrefObsSetCh(['C' num2str(f(1))], sys_c));
                    end
                end
            end
            min_ep_thrs = 50;
            if this.time.length < min_ep_thrs
                min_ep_thrs = 1;
            end
            
            last_ep_coarse = min(100, this.time.length);
            ep_coarse = 1 : last_ep_coarse;
            while(not( sum(sum(obs_set.obs(ep_coarse,:) ~= 0, 2) > 2) > min_ep_thrs) & sum(ep_coarse == this.time.length)  == 0) % checking if the selected epochs contains at least some usabele obseravables
                ep_coarse = [ep_coarse ep_coarse(end)+1];
                ep_coarse = min(ep_coarse,this.time.length);
            end
            this.initAvailIndex(ep_coarse);
            this.updateAllTOT();
            
            this.log.addMessage(this.log.indent('Getting coarse position on subsample of data'))
            
            dpos = 3000; % 3 km - entry condition
            while max(abs(dpos)) > 10
                [dpos, s0] = this.codeStaticPositioning(ep_coarse);
            end
            if s0 > 0
                this.updateAzimuthElevation()
                this.updateErrTropo();
                if ~this.isMultiFreq()
                    this.updateErrIono();
                end
                this.codeStaticPositioning(ep_coarse, 15);
            end
        end
        
        function remBadTracking(this) %%% important check!! if ph obervation with no code are deleted elsewhere
            % requires approximate position and approx clock estimate
            [pr, id_pr] = this.getPseudoRanges;
            %[ph, wl, id_ph] = this.getPhases;
            sensor =  pr - this.getSyntPrObs - repmat(this.dt,1,size(pr,2)) * Core_Utils.V_LIGHT;
            sensor = bsxfun(@minus,sensor,median(sensor,2, 'omitnan'));
            bad_track = abs(sensor) > 1e5;
            bad_track = flagExpand(bad_track, 2);
            pr(bad_track) = 0;
            %ph(bad_track) = 0;
            this.setPseudoRanges(pr, id_pr);
            %this.setPhases(ph, wl, id_ph);
        end
        
        function adjustPrAmbiguity(this)
            % sometimes the receiver might fail to resolve the pseudorange ambifuity
            [pr, id_pr] = this.getPseudoRanges;
            %[ph, wl, id_ph] = this.getPhases;
            sensor =  pr - this.getSyntPrObs;
            dt = median(zero2nan(sensor),2,'omitnan');
            sensor = sensor - repmat(dt,1,size(pr,2));
            pr_amb = 1e-3*Core_Utils.V_LIGHT;
            pr_amb_idx =  abs(sensor) > 1e4 & fracFNI(sensor/(pr_amb)) < 1e2;
            pr(pr_amb_idx) = pr(pr_amb_idx) - round(sensor(pr_amb_idx)/pr_amb)*pr_amb;
            this.setPseudoRanges(pr, id_pr);
        end
        
        function [dpos, s0] = codeStaticPositioning(this, id_sync, cut_off, num_reweight)
            ls = LS_Manipulator(this.cc);
            if nargin < 2
                if ~isempty(this.id_sync)
                    id_sync = this.id_sync;
                else
                    id_sync = 1 : this.length();
                end
            end
            if nargin < 3
                cut_off = this.state.getCutOff();
            end
            if nargin < 4
                num_reweight = 0;
            end
            ls.setUpCodeSatic( this, id_sync, cut_off);
            ls.Astack2Nstack();
            [x, res, s0] = ls.solve();
            
            % REWEIGHT ON RESIDUALS -> (not well tested , uncomment to
            % enable)
            for i = 1 : num_reweight
                ls.reweightHuber();
                ls.Astack2Nstack();
                [x, res, s0] = ls.solve();
            end
            
            if isempty(x)
                dpos = [0 0 0];
                s0 = 0;
            else
                dpos = [x(x(:,2) == 1,1) x(x(:,2) == 2,1) x(x(:,2) == 3,1)];
                if isempty(dpos)
                    dpos = [0 0 0];
                end
                this.xyz = repmat(this.getMedianPosXYZ(), size(dpos,1),1) + dpos;
                dt = x(x(:,2) == 6,1);
                this.dt = zeros(this.time.length,1);
                this.dt(ls.true_epoch,1) = dt ./ Core_Utils.V_LIGHT;
                isb = x(x(:,2) == 4,1);
                this.sat.res = zeros(this.length, this.parent.cc.getMaxNumSat());
                % LS does not know the max number of satellite stored
                dsz = max(id_sync) - size(res,1);
                if dsz == 0
                    this.sat.res(id_sync, ls.sat_go_id) = res(id_sync, ls.sat_go_id);
                else
                    if dsz > 0
                        id_sync = id_sync(1 : end - dsz);
                    end
                    this.sat.res(id_sync, ls.sat_go_id) = res(id_sync, ls.sat_go_id);
                end
                this.quality_info.s0_ip = s0;
                this.quality_info.n_epochs = ls.n_epochs;
                this.quality_info.n_obs = size(ls.epoch, 1);
                this.quality_info.n_out = sum(this.sat.outliers_ph_by_ph(:));
                this.quality_info.n_sat = length(unique(ls.sat));
                this.quality_info.n_sat_max = max(hist(unique(ls.epoch * 1000 + ls.sat), ls.n_epochs));
                this.quality_info.fixing_ratio = 0;
            end
        end
        
        function [dpos, s0, ls] = codeDynamicPositioning(this, id_sync, cut_off)
            ls = LS_Manipulator(this.cc);
            if nargin < 2
                if ~isempty(this.id_sync)
                    id_sync = this.id_sync;
                else
                    id_sync = 1 : this.length();
                end
            end
            if nargin < 3
                cut_off = this.state.getCutOff();
            end
            ls.setUpCodeDynamic( this, id_sync, cut_off);
            ls.Astack2Nstack();
            [x, res, s0] = ls.solve();
            
            % REWEIGHT ON RESIDUALS -> (not well tested , uncomment to
            % enable)
            %             ls.reweightHuber();
            %             ls.Astack2Nstack();
            %             [x, res, s02] = ls.solve();
            
            dpos = [x(x(:,2) == 1,1) x(x(:,2) == 2,1) x(x(:,2) == 3,1)];
            if size(this.xyz,1) == 1
                this.xyz = repmat(this.xyz,this.time.length,1);
            end
            this.xyz = bsxfun(@plus, this.xyz(id_sync,:), dpos);
            dt = x(x(:,2) == 6,1);
            this.dt = zeros(this.time.length,1);
            this.dt(ls.true_epoch,1) = dt ./ Core_Utils.V_LIGHT;
            isb = x(x(:,2) == 4,1);
            this.sat.res = zeros(this.length, this.parent.cc.getMaxNumSat());
            % LS does not know the max number of satellite stored
            
            
            this.sat.res = zeros(this.length, this.parent.cc.getMaxNumSat());
            dsz = max(id_sync) - size(res,1);
            if dsz == 0
                this.sat.res(id_sync, ls.sat_go_id) = res(id_sync, ls.sat_go_id);
            else
                if dsz > 0
                    id_sync = id_sync(1 : end - dsz);
                end
                this.sat.res(id_sync, ls.sat_go_id) = res(id_sync, ls.sat_go_id);
            end
        end
        
        function s0 = initDynamicPositioning(this)
            % SYNTAX
            %   this.StaticPositioning(obs, prn, sys, flag)
            %
            % INPUT
            % obs : observations [meters]
            % prn : prn of observations
            % sys : sys of observations
            % flag : name of observation [obs_code1 obs_code2 comb_code]
            %        comb_code --> Iono Free = I
            % OUTPUTt_glo11.
            %
            %
            %   Get positioning using code observables
            
            
            if this.isEmpty()
                this.log.addError('Static positioning failed: the receiver object is empty');
            else
                if isempty(this.id_sync)
                    this.id_sync = 1 : this.time.length;
                end
                % check if the epochs are present
                % getting the observation set that is going to be used in
                % setUPSA
                obs_set = Observation_Set();
                if this.isMultiFreq() %% case multi frequency
                    for sys_c = this.cc.sys_c
                        obs_set.merge(this.getPrefIonoFree('C', sys_c));
                    end
                else
                    for sys_c = this.cc.sys_c
                        f = this.getFreqs(sys_c);
                        obs_set.merge(this.getPrefObsSetCh(['C' num2str(f(1))], sys_c));
                    end
                end
                
                if sum(this.hasAPriori) == 0 %%% if no apriori information on the position
                    coarsePositioning(this, obs_set)
                end
                
                
                this.updateAllAvailIndex();
                this.updateAllTOT();
                this.updateAzimuthElevation()
                this.updateErrTropo();
                if ~this.isMultiFreq()
                    this.updateErrIono();
                end
                this.log.addMessage(this.log.indent('Improving estimation'))
                this.codeDynamicPositioning(this.id_sync, 15);
                
                this.updateAllTOT();
                this.log.addMessage(this.log.indent('Final estimation'))
                [~, s0, ls] = this.codeDynamicPositioning(this.id_sync, 15);
                this.log.addMessage(this.log.indent(sprintf('Estimation sigma02 %.3f m', s0) ))
                this.quality_info.s0_ip = s0;
                this.quality_info.n_epochs = ls.n_epochs;
                this.quality_info.n_obs = size(ls.epoch, 1);
                this.quality_info.n_out = sum(this.sat.outliers_ph_by_ph(:));
                this.quality_info.n_sat = length(unique(ls.sat));
                this.quality_info.n_sat_max = max(hist(unique(ls.epoch * 1000 + ls.sat), ls.n_epochs));
                this.quality_info.fixing_ratio = 0; 
                
                % final estimation of time of flight
                this.updateAllAvailIndex()
                this.updateAllTOT();
                [~, s0] = this.codeDynamicPositioning(this.id_sync, 15);
            end
        end
        
        function [obs, prn, sys, flag] = getBestCodeObs(this)
            % INPUT
            % OUPUT:
            %    obs = observations [n_obs x n_epoch];
            %    prn = satellite prn [n_obs x 1];
            %    sys = system [n_obs x 1];
            %    flag = flag of the observation [ n_obs x 7] iono free
            %    combination are labeled with the obs code of both observations
            %  get "best" avaliable code or code combination for the given system
            n_epoch = size(this.obs,2);
            obs = [];
            sys = [];
            prn = [];
            flag = [];
            for i = unique(this.go_id)'
                
                sat_idx = this.findObservableByFlag('C',i);
                sat_idx = sat_idx(this.active_ids(sat_idx));
                if ~isempty(sat_idx)
                    % get epoch for which iono free is possible
                    sat_obs = this.obs(sat_idx,:);
                    av_idx = sum((sat_obs > 0),1)>0;
                    freq = str2num(this.obs_code(sat_idx,2)); %#ok<ST2NM>
                    u_freq = unique(freq);
                    if length(u_freq)>1
                        sat_freq = (sat_obs > 0) .*repmat(freq,1,n_epoch);
                        u_freq_sat = zeros(length(u_freq),n_epoch);
                        for e = 1 : length(u_freq)
                            u_freq_sat(e,:) = sum(sat_freq == u_freq(e))>0;
                        end
                        iono_free = sum(u_freq_sat)>1;
                    else
                        iono_free = false(1,n_epoch);
                    end
                    freq_list = this.cc.getSys(this.cc.system(i)).CODE_RIN3_2BAND;
                    track_list = this.cc.getSys(this.cc.system(i)).CODE_RIN3_ATTRIB;
                    if sum(iono_free > 0)
                        %this.sat.avail_index(:,i) = iono_free; % epoch for which observation is present
                        % find first freq obs
                        to_fill_epoch = iono_free;
                        first_freq = [];
                        f_obs_code = [];
                        ff_idx = zeros(n_epoch,1);
                        for f = 1 :length(freq_list)
                            track_prior = track_list{f};
                            for c = 1:length(track_prior)
                                if sum(to_fill_epoch) > 0
                                    [obs_tmp,idx_tmp] = this.getObs(['C' freq_list(f) track_prior(c)],this.cc.system(i),this.cc.prn(i));
                                    %obs_tmp(obs_tmp==0) = nan;
                                    if ~isempty(obs_tmp)
                                        first_freq = [first_freq; zeros(1,n_epoch)];
                                        first_freq(end, to_fill_epoch) = obs_tmp(to_fill_epoch);
                                        ff_idx(to_fill_epoch) = size(first_freq,1);
                                        f_obs_code = [f_obs_code; this.obs_code(idx_tmp,:)];
                                        to_fill_epoch = to_fill_epoch & (obs_tmp == 0);
                                    end
                                end
                            end
                        end
                        % find second freq obs
                        to_fill_epoch = iono_free;
                        second_freq = [];
                        s_obs_code = [];
                        sf_idx = zeros(n_epoch,1);
                        for f = 1 :length(freq_list)
                            track_prior = track_list{f};
                            for c = 1:length(track_prior)
                                if sum(to_fill_epoch) > 0
                                    [obs_tmp,idx_tmp] = this.getObs(['C' freq_list(f) track_prior(c)],this.cc.system(i),this.cc.prn(i));
                                    %obs_tmp = zero2nan(obs_tmp);
                                    
                                    % check if obs has been used already as first frequency
                                    if ~isempty(obs_tmp)
                                        
                                        ff_ot_i = find(sum(f_obs_code(:,1:2) == repmat(this.obs_code(idx_tmp,1:2),size(f_obs_code,1),1),2)==2);
                                        if ~isempty(ff_ot_i)
                                            obs_tmp(sum(first_freq(ff_ot_i,:),1)>0) = 0; % delete epoch where the obs has already been used for the first frequency
                                            
                                        end
                                        
                                        if sum(obs_tmp(to_fill_epoch)>0)>0 % if there is some new observation
                                            second_freq = [second_freq; zeros(1,n_epoch)];
                                            second_freq(end, to_fill_epoch) = obs_tmp(to_fill_epoch);
                                            sf_idx(to_fill_epoch) = size(second_freq,1);
                                            s_obs_code = [s_obs_code; this.obs_code(idx_tmp,:)];
                                            to_fill_epoch = to_fill_epoch & (obs_tmp == 0);
                                        end
                                    end
                                end
                            end
                        end
                        first_freq  = zero2nan(first_freq);
                        second_freq = zero2nan(second_freq);
                        % combine the two frequencies
                        for k = 1 : size(f_obs_code,1)
                            for y = 1 : size(s_obs_code,1)
                                inv_wl1 = 1/this.wl(this.findObservableByFlag(f_obs_code(k,:),i));
                                inv_wl2 = 1/this.wl(this.findObservableByFlag(s_obs_code(y,:),i));
                                %                                 if ((inv_wl1).^2 - (inv_wl2).^2) == 0
                                %                                     keyboard
                                %                                 end
                                
                                obs_tmp = ((inv_wl1).^2 .* first_freq(k,:) - (inv_wl2).^2 .* second_freq(y,:))./ ( (inv_wl1).^2 - (inv_wl2).^2 );
                                obs_tmp(isnan(obs_tmp)) = 0;
                                if sum(obs_tmp>0)>0
                                    obs = [obs; obs_tmp];
                                    [t_sys , t_prn] = this.getSysPrn(i);
                                    prn = [prn; t_prn];
                                    sys = [sys; t_sys];
                                    flag = [flag; [f_obs_code(k,:) s_obs_code(y,:) 'I' ]];
                                end
                            end
                        end
                        %                     end
                        %                     if sum(xor(av_idx, iono_free))>0
                    else % do not mix iono free and not combined observations
                        % find best code
                        to_fill_epoch = av_idx;
                        %this.sat.avail_index(:,i) = av_idx; % epoch for which observation is present
                        for f = 1 :length(freq_list)
                            track_prior = track_list{f};
                            for c = 1:length(track_prior)
                                if sum(to_fill_epoch) > 0
                                    [obs_tmp,idx_tmp] = this.getObs(['C' num2str(freq_list(f)) track_prior(c)],this.cc.system(i),this.cc.prn(i));
                                    if ~isempty(obs_tmp)
                                        obs = [obs; zeros(1,n_epoch)];
                                        obs(end,to_fill_epoch) = obs_tmp(to_fill_epoch);
                                        prn = [prn; this.cc.prn(i)];
                                        sys = [sys; this.cc.system(i)];
                                        flag = [flag; sprintf('%-7s',this.obs_code(idx_tmp,:))];
                                        to_fill_epoch = to_fill_epoch & (obs_tmp < 0);
                                    end
                                end
                            end
                        end
                        
                    end
                    
                end
            end
            % remove obs for which coordinates of satellite are not available
            o = 1;
            while (o <= length(prn))
                s = this.cc.getIndex(sys(o),prn(o));
                o_idx_l = obs(o,:)>0;
                times = this.time.getSubSet(o_idx_l);
                times.addSeconds(-obs(o,o_idx_l)' / Core_Utils.V_LIGHT); % add rough time of flight
                xs = this.sat.cs.coordInterpolate(times,s);
                to_remove = isnan(xs(:,1));
                o_idx = find(o_idx_l);
                to_remove = o_idx(to_remove);
                obs(o,to_remove) = 0;
                if sum(obs(o,:)) == 0 % if line has no more observation
                    obs(o,:) = [];
                    prn(o) = [];
                    sys(o) = [];
                    flag(o,:) = [];
                else
                    o = o + 1;
                end
            end
        end
        
        function computeBasicPosition(this, sys_c)
            % Compute a very simple position from code observations
            % without applying any corrections
            %
            % SYNTAX
            %   this.computeBasicPosition();
            
            if this.isEmpty()
                this.log.addError('Pre-Processing failed: the receiver object is empty');
            else
                if nargin < 2
                    sys_c = this.cc.sys_c;
                end
                this.setActiveSys(intersect(this.getActiveSys, this.sat.cs.getAvailableSys));
                this.remBad();
                % correct for raw estimate of clock error based on the phase measure
                this.correctTimeDesync();
                this.initPositioning(sys_c);
            end
        end
        
        function preProcessing(this, sys_c, flag_apply_corrections)
            % Do all operation needed in order to preprocess the data
            % remove bad observation (spare satellites or bad epochs from CRX)
            % Apply active corrections to the data
            %
            % INPUT 
            %   sys_c                      constellation to be used as array of char e.g. 'GER'
            %   flag_apply_corrections     flag to compute and apply active correction
            %
            % SYNTAX
            %   this.preProcessing(sys_c);
            if nargin < 3
                flag_apply_corrections = true;
            end
            
            if this.isEmpty()
                this.log.addError('Pre-Processing failed: the receiver object is empty');
            else
                this.pp_status = false;
                if nargin < 2
                    sys_c = this.cc.sys_c;
                end
                this.setActiveSys(intersect(this.getActiveSys, this.sat.cs.getAvailableSys));
                this.remBad();
                
                this.remUnderSnrThr(this.state.getSnrThr());
                % correct for raw estimate of clock error based on the phase measure
                [is_pr_jumping, is_ph_jumping] = this.correctTimeDesync();
                % this.TEST_smoothCodeWithDoppler(51);
                % code only solution
                this.importMeteoData();
                this.initTropo();
                
                if (this.state.isOutlierRejectionOn())
                    this.remBadPrObs(150);
                end
                this.remShortArc(this.state.getMinArc); 
                this.remEmptyObs();
                
                if this.getNumPrEpochs == 0
                    this.log.addError('Pre-Processing failed: the receiver object is empty');
                else
                    s02 = this.initPositioning(sys_c); %#ok<*PROPLC>
                    if (s02 == 0)
                        this.log.addWarning(sprintf('Code solution have not been computed, something is wrong in the current dataset'));
                    elseif (min(s02) > this.S02_IP_THR)
                        this.log.addWarning(sprintf('Very BAD code solution => something is proably wrong (s02 = %.2f)', s02));
                    else
                        this.remUnderCutOff();
                        this.setAvIdx2Visibility();
                        this.meteo_data = [];
                        this.importMeteoData(); % now with more precise coordinates
                        
                        % if the clock is stable I can try to smooth more => this.smoothAndApplyDt([0 this.length/2]);
                        this.dt_ip = simpleFill1D(this.dt, this.dt == 0, 'linear') + this.dt_pr; % save init_positioning clock
                        % smooth clock estimation
                        this.smoothAndApplyDt(0, is_pr_jumping, is_ph_jumping);
                        
                        % update azimuth elevation
                        this.updateAzimuthElevation();
                        % Add a model correction for time desync -> observations are now referred to nominal time  #14
                        this.shiftToNominal();
                        
                        this.updateAllTOT(true);
                        this.correctPhJump();
                        
                        if flag_apply_corrections
                            % apply various corrections
                            this.sat.cs.toCOM(); % interpolation of attitude with 15min coordinate might possibly be inaccurate switch to center of mass (COM)
                            
                            this.updateAzimuthElevation();
                            if this.state.isAprIono || this.state.getIonoManagement == 3
                                this.updateErrIono();
                                this.applyIonoModel();
                            end
                            
                            %ph0 = this.getPhases();
                            this.applyPCV();
                            %ph1 = this.getPhases();
                            %corr.pcv = ph1 - ph0;
                            this.applyPoleTide();
                            %ph2 = this.getPhases();
                            %corr.pt = ph2 - ph1;
                            this.applyPhaseWindUpCorr();
                            %ph3 = this.getPhases();
                            %corr.pwu = ph3 - ph2;
                            this.applySolidEarthTide();
                            %ph4 = this.getPhases();
                            %corr.set = ph4 - ph3;
                            this.applyShDelay();
                            %ph5 = this.getPhases();
                            %corr.shd = ph5 - ph4;
                            this.applyOceanLoading();
                            %ph6 = this.getPhases();
                            %corr.ocl = ph6 - ph5;
                            this.applyAtmLoad();
                            this.applyHOI();
                            
                            if this.state.isRepairOn()
                                this.repairPhases();
                            end
                            
                            this.detectOutlierMarkCycleSlip();
                            this.coarseAmbEstimation();
                            this.pp_status = true;
                        end
                    end
                end
            end
        end
        
        function staticPPP(this, sys_list, id_sync)
            % compute a static PPP solution
            %
            % SYNTAX
            %   this.parent.staticPPP(<sys_list>, <id_sync>)
            %
            % EXAMPLE:
            %   Use the full dataset to compute a PPP solution
            %    - this.parent.staticPPP();
            %
            %   Use just GPS + GLONASS + Galileo to compute a PPP solution
            %   using epochs from 501 to 2380
            %    - this.parent.staticPPP('GRE', 501:2380);
            %
            %   Use all the available satellite system to compute a PPP solution
            %   using epochs from 501 to 2380
            %    - this.parent.staticPPP([], 500:2380);
            
            if this.isEmpty()
                this.log.addError('staticPPP failed The receiver object is empty');
            elseif ~this.isPreProcessed()
                if ~isempty(this.quality_info.s0_ip) && (this.quality_info.s0_ip < Inf)
                    this.log.addError('Pre-Processing is required to compute a PPP solution');
                else
                    this.log.addError('Pre-Processing failed: skipping PPP solution');
                end
            elseif this.quality_info.s0_ip > 10
                this.log.addError('Pre-Processing quality is too bad to proceed with PPP computation');
            else
                if nargin >= 2
                    if ~isempty(sys_list)
                        this.setActiveSys(sys_list);
                    end
                end
                if nargin < 3
                    id_sync = (1 : this.time.length())';
                end
                
                id_sync_in = id_sync;
                this.log.addMarkedMessage(['Computing PPP solution using: ' this.getActiveSys()]);
                this.log.addMessage(this.log.indent('Preparing the system'));
                %this.updateAllAvailIndex
                %this.updateAllTOT
                if this.state.getAmbFixPPP()
                    this.coarseAmbEstimation();
                end
                ls = LS_Manipulator(this.cc);
                pos_idx = [];
                
                order_tropo = this.state.spline_tropo_order;
                order_tropo_g = this.state.spline_tropo_gradient_order;
                tropo_rate = [this.state.spline_rate_tropo*double(order_tropo>0)  this.state.spline_rate_tropo_gradient*double(order_tropo_g>0)];
                id_sync = ls.setUpPPP(this, id_sync,'',false, pos_idx, tropo_rate);
                if isempty(id_sync)
                    this.log.addWarning('No processable epochs found, skipping PPP');
                else
                    ls.Astack2Nstack();
                    time = this.time.getSubSet(id_sync);
                    rate = time.getRate();
                    ls.setTimeRegularization(ls.PAR_REC_CLK, (this.state.std_clock)^2 / 3600* rate); % really small regularization
                    if this.state.flag_tropo
                        if order_tropo == 0
                            ls.setTimeRegularization(ls.PAR_TROPO, (this.state.std_tropo)^2 / 3600 * rate );% this.state.std_tropo / 3600 * rate  );
                        else
                            ls.setTimeRegularization(ls.PAR_TROPO, (this.state.std_tropo)^2 / 3600 * tropo_rate(1) );% this.state.std_tropo / 3600 * rate  );
                        end
                    end
                    if this.state.flag_tropo_gradient
                        if order_tropo_g == 0
                            ls.setTimeRegularization(ls.PAR_TROPO_N, (this.state.std_tropo_gradient)^2 / 3600 * rate );%this.state.std_tropo / 3600 * rate );
                            ls.setTimeRegularization(ls.PAR_TROPO_E, (this.state.std_tropo_gradient)^2 / 3600 * rate );%this.state.std_tropo  / 3600 * rate );
                        else
                            ls.setTimeRegularization(ls.PAR_TROPO_N, (this.state.std_tropo_gradient)^2 / 3600 * tropo_rate(2) );%this.state.std_tropo / 3600 * rate );
                            ls.setTimeRegularization(ls.PAR_TROPO_E, (this.state.std_tropo_gradient)^2 / 3600 * tropo_rate(2));%this.state.std_tropo  / 3600 * rate );
                        end
                    end
                    this.log.addMessage(this.log.indent('Solving the system'));
                    [x, res, s0, ~, l_fixed] = ls.solve();
                    % REWEIGHT ON RESIDUALS
                    if this.state.getReweightPPP > 1
                        switch this.state.getReweightPPP()
                            case 2, ls.reweightHuber;
                            case 3, ls.reweightHubNoThr;
                            case 4, ls.reweightDanish;
                            case 5, ls.reweightDanishWM;
                            case 6, ls.reweightTukey;
                            case 7, ls.snooping;
                            case 8, ls.snoopingGatt(6); % <= sensible parameter THR => to be put in settings(?)
                        end
                        ls.Astack2Nstack();
                        [x, res, s0, ~, l_fixed] = ls.solve();
                    end
                    id_sync = ls.true_epoch;
                    
                    if isempty(this.zwd) || all(isnan(this.zwd))
                        this.zwd = zeros(this.time.length(), 1);
                    end
                    if isempty(this.apr_zhd) || all(isnan(this.apr_zhd))
                        this.apr_zhd = zeros(this.time.length(),1);
                    end
                    if isempty(this.ztd) || all(isnan(this.ztd))
                        this.ztd = zeros(this.time.length(),1);
                    end
                    
                    n_sat = size(this.sat.el,2);
                    if isempty(this.sat.slant_td)
                        this.sat.slant_td = zeros(this.time.length(), n_sat);
                    end
                    
                    
                    
                    this.id_sync = id_sync;
                    
                    this.sat.res = zeros(this.time.length, n_sat);
                    this.sat.res(id_sync, ls.sat_go_id) = res(id_sync, ls.sat_go_id);
                    this.n_sat_ep = uint8(sum(this.sat.res ~= 0,2));
                    
                    %this.id_sync = unique([serialize(this.id_sync); serialize(id_sync)]);
                    
                    coo = [x(x(:,2) == 1,1) x(x(:,2) == 2,1) x(x(:,2) == 3,1)];
                    if isempty(coo)
                        coo = [0 0 0];
                    end
                    
                    clock = x(x(:,2) == 6,1);
                    tropo = x(x(:,2) == 7,1);
                    amb = x(x(:,2) == 5,1);
                    
                    % saving matrix of float ambiguities
                    amb_mat = zeros(length(id_sync), length(ls.go_id_amb));
                    id_ok = ~isnan(ls.amb_idx);
                    amb_mat(id_ok) = amb(ls.amb_idx(id_ok));
                    this.sat.amb_mat = nan(this.length, this.parent.cc.getMaxNumSat);
                    this.sat.amb_mat(id_sync,ls.go_id_amb) = amb_mat;
                    
                    gntropo = x(x(:,2) == 8,1);
                    getropo = x(x(:,2) == 9,1);
                    this.log.addMessage(this.log.indent(sprintf('DEBUG: sigma0 = %f', s0)));
                    
                    valid_ep = ls.true_epoch;
                    this.dt(valid_ep, 1) = clock / Core_Utils.V_LIGHT;
                    this.sat.amb_idx = nan(this.length, this.parent.cc.getMaxNumSat);
                    this.sat.amb_idx(id_sync,ls.go_id_amb(ls.phase_idx)) = ls.amb_idx;
                    this.if_amb = amb; % to test ambiguity fixing
                    this.quality_info.s0 = s0;
                    this.quality_info.n_epochs = ls.n_epochs;
                    this.quality_info.n_obs = size(ls.epoch, 1);
                    this.quality_info.n_out = sum(this.sat.outliers_ph_by_ph(:));
                    this.quality_info.n_sat = length(unique(ls.sat));
                    this.quality_info.n_sat_max = max(hist(unique(ls.epoch * 1000 + ls.sat), ls.n_epochs));
                    if this.state.getAmbFixPPP
                        this.quality_info.fixing_ratio = sum(l_fixed)/numel(l_fixed);
                    end
                    
                    if s0 > 0.10
                        this.log.addWarning(sprintf('PPP solution failed, s02: %6.4f   - no update to receiver fields',s0))
                    end
                    if s0 < 0.5 % with over 50cm of error the results are not meaningfull
                        if isempty(pos_idx)
                            this.xyz = this.xyz + coo;
                        else
                            this.xyz = this.xyz + coo(2,:);
                        end
                        if this.state.flag_tropo
                            zwd = this.getZwd();
                            zwd_tmp = zeros(size(this.zwd));
                            zwd_tmp(this.id_sync) = zwd;
                            if order_tropo == 0
                                this.zwd(valid_ep) = zwd_tmp(valid_ep) + tropo;
                            else
                                tropo_dt = rem(ls.true_epoch-1,tropo_rate(1)/this.time.getRate)/(tropo_rate(1)/this.time.getRate);
                                
                                spline_base = Core_Utils.spline(tropo_dt,order_tropo);
                                this.zwd(valid_ep) = zwd_tmp(valid_ep) + sum(spline_base.*tropo(repmat(ls.tropo_idx,1,order_tropo+1)+repmat((0:order_tropo),numel(ls.tropo_idx),1)),2);
                            end
                            this.ztd(valid_ep) = this.zwd(valid_ep) + this.apr_zhd(valid_ep);
                            this.pwv = nan(size(this.zwd));
                            if ~isempty(this.meteo_data)
                                degCtoK = 273.15;
                                [~,Tall, H] = this.getPTH();
                                % weighted mean temperature of the atmosphere over Alaska (Bevis et al., 1994)
                                Tm = (Tall(valid_ep) + degCtoK)*0.72 + 70.2;
                                
                                % Askne and Nordius formula (from Bevis et al., 1994)
                                Q = (4.61524e-3*((3.739e5./Tm) + 22.1));
                                
                                % precipitable Water Vapor
                                this.pwv(valid_ep) = this.zwd(valid_ep) ./ Q;
                            end
                            this.sat.amb = amb;
                        end
                        if this.state.flag_tropo_gradient
                            if isempty(this.tgn) || all(isnan(this.tgn))
                                this.tgn = nan(this.time.length,1);
                            end
                            if order_tropo_g == 0
                                this.tgn(valid_ep) =  nan2zero(this.tgn(valid_ep)) + gntropo;
                            else
                                tropo_dt = rem(ls.true_epoch-1,tropo_rate(2)/this.time.getRate)/(tropo_rate(2)/this.time.getRate);
                                spline_base = Core_Utils.spline(tropo_dt,order_tropo_g);
                                this.tgn(valid_ep) =  nan2zero(this.tgn(valid_ep)) + sum(spline_base.*gntropo(repmat(ls.tropo_g_idx,1,order_tropo_g+1)+repmat((0:order_tropo_g),numel(ls.tropo_g_idx),1)),2);
                            end
                            if isempty(this.tge) || all(isnan(this.tge))
                                this.tge = nan(this.time.length,1);
                            end
                            if order_tropo_g == 0
                                this.tge(valid_ep) = nan2zero(this.tge(valid_ep))  + getropo;
                            else
                                this.tge(valid_ep) = nan2zero(this.tge(valid_ep)) + sum(spline_base.*getropo(repmat(ls.tropo_g_idx,1,order_tropo_g+1)+repmat((0:order_tropo_g),numel(ls.tropo_g_idx),1)),2);
                            end
                        end
                        this.updateErrTropo();
                        % -------------------- estimate additional coordinate set
                        if this.state.flag_coo_rate
                            for i = 1 : 3
                                if this.state.coo_rates(i) ~= 0
                                    pos_idx = [ones(sum(this.time < this.out_start_time),1)];
                                    time_1 = this.out_start_time.getCopy;
                                    time_2 = this.out_start_time.getCopy;
                                    time_2.addSeconds(min(this.state.coo_rates(i),this.out_stop_time - time_2));
                                    for j = 0 : (ceil((this.out_stop_time - this.out_start_time)/this.state.coo_rates(i)) - 1)
                                        pos_idx = [pos_idx; (length(unique(pos_idx))+1)*ones(sum(this.time >= time_1 & this.time < time_2),1)];
                                        time_1.addSeconds(this.state.coo_rates(i));
                                        time_2.addSeconds(min(this.state.coo_rates(i),this.out_stop_time - time_2) );
                                    end
                                    pos_idx = [pos_idx; (length(unique(pos_idx))+1)*ones(sum(this.time >= this.out_stop_time),1);];
                                    
                                    ls = LS_Manipulator(this.cc);
                                    id_sync = ls.setUpPPP(this, id_sync_in,'',false, pos_idx);
                                    ls.Astack2Nstack();
                                    
                                    time = this.time.getSubSet(id_sync_in);
                                    
                                    rate = time.getRate();
                                    
                                    ls.setTimeRegularization(ls.PAR_REC_CLK, (this.state.std_clock)^2 / 3600 * rate); % really small regularization
                                    ls.setTimeRegularization(ls.PAR_TROPO, (this.state.std_tropo)^2 / 3600 * rate );% this.state.std_tropo / 3600 * rate  );
                                    if this.state.flag_tropo_gradient
                                        ls.setTimeRegularization(ls.PAR_TROPO_N, (this.state.std_tropo_gradient)^2 / 3600 * rate );%this.state.std_tropo / 3600 * rate );
                                        ls.setTimeRegularization(ls.PAR_TROPO_E, (this.state.std_tropo_gradient)^2 / 3600 * rate );%this.state.std_tropo  / 3600 * rate );
                                    end
                                    this.log.addMessage(this.log.indent('Solving the system'));
                                    [x, res, s0]  = ls.solve();
                                    
                                    coo = [x(x(:,2) == 1,1) x(x(:,2) == 2,1) x(x(:,2) == 3,1)];
                                    time_coo = this.out_start_time.getCopy;
                                    time_coo.addSeconds([0 : this.state.coo_rates(i) :  (this.out_stop_time - this.out_start_time)]);
                                    sub_coo = struct();
                                    sub_coo.coo = Coordinates.fromXYZ(repmat(this.xyz,size(coo,1),1)+ coo);
                                    sub_coo.time = time_coo.getCopy();
                                    sub_coo.rate = this.state.coo_rates(i);
                                    if isempty(this.add_coo)
                                        this.add_coo = sub_coo;
                                    else
                                        this.add_coo(end+1) = sub_coo;
                                    end
                                end
                                
                            end
                        end
                        %this.pushResult();
                    end
                end
            end
        end
        
        function dynamicPPP(this, sys_list, id_sync)
            % compute a static PPP solution
            %
            % SYNTAX
            %   this.parent.staticPPP(<sys_list>, <id_sync>)
            %
            % EXAMPLE:
            %   Use the full dataset to compute a PPP solution
            %    - this.parent.staticPPP();
            %
            %   Use just GPS + GLONASS + Galileo to compute a PPP solution
            %   using epochs from 501 to 2380
            %    - this.parent.staticPPP('GRE', 501:2380);
            %
            %   Use all the available satellite system to compute a PPP solution
            %   using epochs from 501 to 2380
            %    - this.parent.staticPPP([], 500:2380);
            
            if this.isEmpty()
                this.log.addError('staticPPP failed The receiver object is empty');
            elseif ~this.isPreProcessed()
                if (this.quality_info.s0_ip < Inf)
                    this.log.addError('Pre-Processing is required to compute a PPP solution');
                else
                    this.log.addError('Pre-Processing failed: skipping PPP solution');
                end
            else
                if nargin >= 2
                    if ~isempty(sys_list)
                        this.setActiveSys(sys_list);
                    end
                end
                
                if nargin < 3
                    id_sync = (1 : this.time.length())';
                end
                
                this.log.addMarkedMessage(['Computing PPP solution using: ' this.getActiveSys()]);
                this.log.addMessage(this.log.indent('Preparing the system'));
                %this.updateAllAvailIndex
                %this.updateAllTOT
                ls = LS_Manipulator(this.cc);
                id_sync = ls.setUpPPP(this, id_sync, this.state.getCutOff, true);
                ls.Astack2Nstack();
                
                time = this.time.getSubSet(id_sync);
                
                if isempty(this.zwd) || all(isnan(this.zwd))
                    this.zwd = zeros(this.time.length(), 1);
                end
                if isempty(this.apr_zhd) || all(isnan(this.apr_zhd))
                    this.apr_zhd = zeros(this.time.length(),1);
                end
                if isempty(this.ztd) || all(isnan(this.ztd))
                    this.ztd = zeros(this.time.length(),1);
                end
                
                n_sat = size(this.sat.el,2);
                if isempty(this.sat.slant_td)
                    this.sat.slant_td = zeros(this.time.length(), n_sat);
                end
                
                rate = time.getRate();
                
                %ls.setTimeRegularization(ls.PAR_CLK, 1e-3 * rate); % really small regularization
                ls.setTimeRegularization(ls.PAR_X, 1 * rate); % really small regularization
                ls.setTimeRegularization(ls.PAR_Y, 1 * rate); % really small regularization
                ls.setTimeRegularization(ls.PAR_Z, 1 * rate); % really small regularization
                ls.setTimeRegularization(ls.PAR_TROPO, (this.state.std_tropo)^2 / 3600 * rate );% this.state.std_tropo / 3600 * rate  );
                if this.state.flag_tropo_gradient
                    ls.setTimeRegularization(ls.PAR_TROPO_N, (this.state.std_tropo_gradient)^2 / 3600 * rate );%this.state.std_tropo / 3600 * rate );
                    ls.setTimeRegularization(ls.PAR_TROPO_E, (this.state.std_tropo_gradient)^2 / 3600 * rate );%this.state.std_tropo  / 3600 * rate );
                end
                this.log.addMessage(this.log.indent('Solving the system'));
                [x, res, s0] = ls.solve();
                % REWEIGHT ON RESIDUALS -> (not well tested , uncomment to
                % enable)
                % ls.reweightHuber();
                % ls.Astack2Nstack();
                % [x, res, s02] = ls.solve();
                this.id_sync = id_sync;
                
                this.sat.res = zeros(this.length, n_sat);
                this.sat.res(id_sync, ls.sat_go_id) = res(id_sync, ls.sat_go_id);
                
                %this.id_sync = unique([serialize(this.id_sync); serialize(id_sync)]);
                
                coo_x    = x(x(:,2) == 1,1);
                coo_y    = x(x(:,2) == 2,1);
                coo_z    = x(x(:,2) == 3,1);
                
                clock = x(x(:,2) == 6,1);
                tropo = x(x(:,2) == 7,1);
                amb = x(x(:,2) == 5,1);
                
                this.sat.res = zeros(this.length, n_sat);
                this.sat.res(id_sync, ls.sat_go_id) = res(id_sync, ls.sat_go_id);
                keyboard
            end
            
        end
        
        function fixPPP(this)
            % coarse estimation of amb
            this.coarseAmbEstimation();
            % apply dt
            this.smoothAndApplyDt(0);
            % remove grupo delay
            this.remGroupDelay();
            % estaimet WL
            mwb = this.getMelWub('1','2','G');
            wl_cycle = mwb.obs./repmat(mwb.wl,size(mwb.obs,1),1);
            wl_cycle = zeros(size(mwb.obs,1),this.cc.getGPS.N_SAT);
            wl_cycle(:,mwb.go_id) = mwb.obs;
            wl_cycle(:,mwb.go_id) = wl_cycle(:,mwb.go_id)./repmat(mwb.wl,size(mwb.obs,1),1);
            wsb = this.sat.cs.getWSB(this.getCentralTime());
            % take off wsb
            wl_cycle = zero2nan(wl_cycle) + repmat(wsb,size(mwb.obs,1),1);
            % get receiver wsb
            wsb_rec = median(zero2nan(wl_cycle(:)) - ceil(zero2nan(wl_cycle(:))),'omitnan');
            wl_cycle = wl_cycle - wsb_rec;
            keyboard
            % estimate narrow lane
            % -> amb VCV ???
            % get undifferenced
            % new estimation round with fixed ambs
        end
        
        function coarseAmbEstimation(this)
           % coarse estimation of the ambiguity
           %
           % SYNTAX:
           % this.coarseAmbEstimation()
           
           [ph, wl, id_ph] = this.getPhases();
           synt_ph = this.getSyntPhases;
           ph_diff = ph - synt_ph;
           amb_idx = Core_Utils.getAmbIdx(this.sat.cicle_slip_ph_by_ph, zero2nan(ph));
           max_amb = max(max(amb_idx));
           for a = 1 : max_amb
               idx_amb = amb_idx == a;
               wla = wl(sum(idx_amb)>0);
               ph(idx_amb) = nan2zero(zero2nan(ph(idx_amb)) - round(median(ph_diff(idx_amb)./wla,'omitnan'))*wla);
           end
           this.setPhases( ph, wl, id_ph);
        end
        
        function coarseAmbEstimationOld(this)
            % estimate coarse ambiguities
            %%% experimental now just for GPS L1 L2
            
            % get geometry free
            wl1 = GPS_SS.L_VEC(1);
            wl2 = GPS_SS.L_VEC(2);
            
            f1 = GPS_SS.F_VEC(1);
            f2 = GPS_SS.F_VEC(2);
            
            gamma = f1^2 / f2^2;
            
            
            
            geom_free = zeros(this.time.length,GPS_SS.N_SAT);
            obs_set =  this.getGeometryFree('C2W','C1W','G');
            obs_set_temp =  this.getIonoFree('L1','L2','G');
            geom_free(:,obs_set.go_id) = obs_set.obs;
            amb_idx = nan(this.time.length, this.parent.cc.getMaxNumSat);
            amb_idx(:,obs_set_temp.go_id) = obs_set_temp.getAmbIdx;
            n_amb  = max(max(amb_idx));
            iono_elong = geom_free / ( 1 -gamma); % Eq (2)
            P1_idx = strLineMatch(this.obs_code, 'C1W')'& this.system == 'G';
            P2_idx = strLineMatch(this.obs_code, 'C2W')'& this.system == 'G';
            P1 = zeros(this.time.length,GPS_SS.N_SAT);
            P2 = zeros(this.time.length,GPS_SS.N_SAT);
            P1(:,this.go_id(P1_idx)) = this.obs(P1_idx,:)';
            P2(:,this.go_id(P2_idx)) = this.obs(P2_idx,:)';
            L1 = zeros(this.time.length,GPS_SS.N_SAT);
            L2 = zeros(this.time.length,GPS_SS.N_SAT);
            L1_idx = strLineMatch(this.obs_code, 'L1C')' & this.system == 'G';
            L1(:,this.go_id(L1_idx)) = this.obs(L1_idx, :)';
            L2_idx = strLineMatch(this.obs_code, 'L2W')' & this.system == 'G';
            L2(:,this.go_id(L2_idx)) = this.obs(L2_idx, :)';
            n1_tilde = (zero2nan(P1) - 2* zero2nan(iono_elong)) / wl1 - zero2nan(L1);
            n2_tilde = (zero2nan(P2) - 2* gamma* zero2nan(iono_elong)) / wl2 - zero2nan(L2);
            
            
            l1_amb = zeros(1,n_amb);
            l2_amb = zeros(1,n_amb);
            for i =1 : n_amb;
                l1_amb(i) = median(n1_tilde(amb_idx == i),'omitnan');
                l2_amb(i) = median(n2_tilde(amb_idx == i),'omitnan');
            end
            
            l1_amb_round = round(l1_amb);
            l1_amb_round(isnan(l1_amb_round)) = 0;
            l2_amb_round = round(l2_amb);
            l2_amb_round(isnan(l2_amb_round)) = 0;
            for i =1 : n_amb;
                idx_amb = amb_idx == i;
                L1(idx_amb) = L1(idx_amb) + l1_amb_round(i);
                L2(idx_amb) = L2(idx_amb) + l2_amb_round(i);
            end
            this.obs(L1_idx, :) = L1(:,this.go_id(L1_idx))';
            this.obs(L2_idx, :) = L2(:,this.go_id(L2_idx))';
        end
        
        function interpResults(this)
            % When computing a solution with subsampling not all the epochs have an estimation
            id_rem = true(this.time.length, 1);
            id_rem(this.id_sync) = false;
            
            if ~(isempty(this.dt))
                this.dt(id_rem) = nan;
                this.dt(id_rem) = interp1(this.time.getEpoch(this.id_sync).getRefTime, this.dt(this.id_sync), this.time.getEpoch(id_rem).getRefTime, 'pchip');
            end
            if ~(isempty(this.apr_zhd))
                this.apr_zhd(id_rem) = nan;
                this.apr_zhd(id_rem) = interp1(this.time.getEpoch(this.id_sync).getRefTime, this.apr_zhd(this.id_sync), this.time.getEpoch(id_rem).getRefTime, 'pchip');
            end
            if ~(isempty(this.ztd))
                this.ztd(id_rem) = nan;
                this.ztd(id_rem) = interp1(this.time.getEpoch(this.id_sync).getRefTime, this.ztd(this.id_sync), this.time.getEpoch(id_rem).getRefTime, 'pchip');
            end
            if ~(isempty(this.zwd))
                this.zwd(id_rem) = nan;
                this.zwd(id_rem) = interp1(this.time.getEpoch(this.id_sync).getRefTime, this.zwd(this.id_sync), this.time.getEpoch(id_rem).getRefTime, 'pchip');
            end
            if ~(isempty(this.pwv))
                this.pwv(id_rem) = nan;
                this.pwv(id_rem) = interp1(this.time.getEpoch(this.id_sync).getRefTime, this.pwv(this.id_sync), this.time.getEpoch(id_rem).getRefTime, 'pchip');
            end
            if ~(isempty(this.tgn))
                this.tgn(id_rem) = nan;
                this.tgn(id_rem) = interp1(this.time.getEpoch(this.id_sync).getRefTime, this.tgn(this.id_sync), this.time.getEpoch(id_rem).getRefTime, 'pchip');
            end
            if ~(isempty(this.tge))
                this.tge(id_rem) = nan;
                this.tge(id_rem) = interp1(this.time.getEpoch(this.id_sync).getRefTime, this.tge(this.id_sync), this.time.getEpoch(id_rem).getRefTime, 'pchip');
            end
            % slant cannot be interpolated easyle, it's better to interpolate slant_std and reconvert them to slant_td
            % not yet implemented
            %if ~(isempty(this.sat.slant_td))
            %    for s = 1 : size(this.sat.slant_td, 2)
            %        this.sat.slant_td(id_rem, s) = nan;
            %        id_ok = ~id_rem & this.sat.el(:, s) > 0 & this.sat.slant_td(:, s) > 0;
            %        id_interp = id_rem & this.sat.el(:, s) > 0;
            %        if sum(id_ok) > 3
            %            this.sat.slant_td(id_interp, s) = interp1(this.time.getEpoch(id_ok).getRefTime, zero2nan(this.sat.slant_td(id_ok, s)), this.time.getEpoch(id_interp).getRefTime, 'pchip');
            %        end
            %    end
            %end
        end
    end
    
    
    % ==================================================================================================================================================
    %% METHODS IMPORT / EXPORT
    % ==================================================================================================================================================
    
    methods
        function exportRinex3(this, file_name)
            % Export the content of the object as RINEX 3
            % SYNTAX
            %   this.exportRinex3(file_name);
            if nargin < 2 || isempty(file_name)
                file_name = fullfile(this.state.getOutDir, [this.parent.getMarkerName4Ch '_' this.time.first.round(86400).toString('yyyymmdd') '.rnx']);
            end
            
            this.remAllCorrections();
            
            % HEADER -------------------------------------------------------------------------------------------------------------------------------------------
            txt = [];
            this.updateRinObsCode();
            
            program = 'goGPS';
            agency = 'GReD s.r.l.';
            
            date_str_UTC = local_time_to_utc(now, 30);
            [date_str_UTC, time_str_UTC] = strtok(date_str_UTC,'T');
            time_str_UTC = time_str_UTC(2:end-1);
            
            %write header
            sys_c = unique(this.system);
            txt = sprintf('%s%9.2f           OBSERVATION DATA    %-19s RINEX VERSION / TYPE\n', txt, 3.03, iif(numel(sys_c) == 1, sys_c, 'M: Mixed'));
            txt = sprintf('%s%-20s%-20s%-20sPGM / RUN BY / DATE \n', txt, program, agency, [date_str_UTC ' ' time_str_UTC ' UTC']);
            txt = sprintf('%s%-60sMARKER NAME         \n', txt, this.parent.marker_name);
            txt = sprintf('%s%-20s                                        MARKER TYPE\n', txt, this.parent.marker_type);
            txt = sprintf('%s%-20s%-40sOBSERVER / AGENCY\n', txt, this.parent.observer, this.parent.agency);
            txt = sprintf('%sRINEX FILE EXPORTED BY goGPS OPEN SOURCE SOFTWARE           COMMENT\n', txt);
            txt = sprintf('%sREFERENCE DEV SITE: https://github.com/goGPS-Project        COMMENT\n', txt);
            txt = sprintf('%s%-20s%-20s%-20sREC # / TYPE / VERS\n', txt, this.parent.number, this.parent.type, this.parent.version);
            txt = sprintf('%s%-20s%-20s                    ANT # / TYPE\n', txt, this.parent.ant, this.parent.ant_type);
            xyz = this.getAPrioriPos();
            if ~any(xyz)
                xyz = this.getMedianPosXYZ();
            end
            txt = sprintf('%s%14.4f%14.4f%14.4f                  APPROX POSITION XYZ\n', txt, xyz(1), xyz(2), xyz(3));
            txt = sprintf('%s%14.4f%14.4f%14.4f                  ANTENNA: DELTA H/E/N\n', txt, this.parent.ant_delta_h, this.parent.ant_delta_en);
            
            sys = this.getActiveSys();
            for s = 1 : length(sys)
                obs_type = this.getAvailableCode(sys(s));
                % Set order CODE PHASE DOPPLER SNR
                obs_type = obs_type([find(obs_type(:,1) == 'C');
                    find(obs_type(:,1) == 'L');
                    find(obs_type(:,1) == 'D');
                    find(obs_type(:,1) == 'S')], :);
                
                % if the code is unknown use 'the least important code' non empty as obs code
                % relative to the band
                for c = find(obs_type(:,3) == ' ')'
                    ss = this.cc.getSys(sys(s));
                    band = (ss.CODE_RIN3_2BAND == obs_type(c,2));
                    code = ss.CODE_RIN3_DEFAULT_ATTRIB{band}(1);
                    obs_type(c, 3) = code;
                end
                n_type = length(obs_type);
                n_line = ceil(n_type / 13);
                tmp = char(32 * ones(n_line * 13, 4));
                tmp(1 : n_type, 1:3) = obs_type;
                tmp = reshape(tmp', 4*13, n_line)';
                txt = sprintf('%s%-1s   %2d %s SYS / # / OBS TYPES\n', txt, char(sys(s)), n_type, tmp(1, :));
                for l = 2 : n_line
                    txt = sprintf('%s       %s SYS / # / OBS TYPES\n', txt, tmp(l, :));
                end
            end
            %txt = sprintf('%sDBHZ                                                        SIGNAL STRENGTH UNIT\n', txt);
            txt = sprintf('%s%10.3f                                                  INTERVAL\n', txt, this.time.getRate());
            txt = sprintf('%s%6d%6d%6d%6d%6d%13.7f     GPS         TIME OF FIRST OBS\n', txt, this.time.first.get6ColDate());
            txt = sprintf('%s%6d%6d%6d%6d%6d%13.7f     GPS         TIME OF LAST OBS\n', txt, this.time.last.get6ColDate());
            txt = sprintf('%sCARRIER PHASE SHIFT removed BY goGPS SOFTWARE.              COMMENT\n', txt);
            for s = 1 : length(sys)
                obs_type = this.getAvailableCode(sys(s));
                % Set order CODE PHASE DOPPLER SNR
                obs_type = obs_type(obs_type(:,1) == 'L', :);
                for c = find(obs_type(:,3) == ' ')'
                    ss = this.cc.getSys(sys(s));
                    band = (ss.CODE_RIN3_2BAND == obs_type(c,2));
                    code = ss.CODE_RIN3_DEFAULT_ATTRIB{band}(1);
                    obs_type(c, 3) = code;
                end
                for l = 1 : size(obs_type, 1)
                    txt = sprintf('%s%-1s %-3s %8.5f                                              SYS / PHASE SHIFT \n', txt, sys(s), obs_type(l, :), 0.0);
                end
            end
            if ~isempty(intersect(sys, 'R'))
                % If glonas is present
                %txt = sprintf('%s C1C    0.000 C1P    0.000 C2C    0.000 C2P    0.000        GLONASS COD/PHS/BIS\n', txt);
                txt = sprintf('%s C1C          C1P          C2C          C2P                 GLONASS COD/PHS/BIS\n', txt);
            end
            txt  = sprintf('%s                                                            END OF HEADER       \n', txt);
            
            fid = fopen(file_name, 'w');
            fprintf(fid, '%s', txt);
            txt = [];
            
            % DATA ---------------------------------------------------------------------------------------------------------------------------------------------
            
            date6col = this.time.get6ColDate();
            flag_ok = 0;
            clock_offset = 0;
            
            obs_code = Core_Utils.code3Char2Num(this.obs_code);
            for ss = sys
                % rin_obs_code tu num;
                obs_type = reshape(this.rin_obs_code.(ss)', 3, length(this.rin_obs_code.(ss))/3)';
                % Set order CODE PHASE DOPPLER SNR
                obs_type = obs_type([find(obs_type(:,1) == 'C');
                    find(obs_type(:,1) == 'L');
                    find(obs_type(:,1) == 'D');
                    find(obs_type(:,1) == 'S')], :);
                
                rin_obs_code.(ss) = Core_Utils.code3Char2Num(obs_type);
                for t = 1 : numel(rin_obs_code.(ss))
                    obs_code(obs_code == rin_obs_code.(ss)(t)) = t;
                end
            end
            
            n_epo = size(this.obs, 2);
            this.w_bar.createNewBar(' Exporting Receiver as Rinex 3.03 file...');
            this.w_bar.setBarLen(n_epo);
            for e = 1 : n_epo
                id_ok = ~isnan(zero2nan(this.obs(:, e)));
                go_id = unique(this.go_id(id_ok));
                if ~isempty(id_ok)
                    %txt = sprintf('%s> %4d %02d %02d %02d %02d %10.7f  %d%3d      %15.12f\n', txt, date6col(e, :), flag_ok, numel(go_id), clock_offset);
                    txt = sprintf('%s> %4d %02d %02d %02d %02d %10.7f  %d%3d\n', txt, date6col(e, :), flag_ok, numel(go_id));
                    for ss = sys % for each satellite system in view at this epoch
                        id_ss = id_ok & this.system' == ss;
                        for prn = unique(this.prn(id_ss))' % for each satellite in view at this epoch (of the current ss)
                            % find which obs type are present
                            id_sat_obs = (id_ss & this.prn == prn);
                            str_obs = char(32 * ones(16, numel(rin_obs_code.(ss))));
                            id_rin_col = obs_code(id_sat_obs);
                            str_obs(:, id_rin_col) = reshape(sprintf('%14.3f  ', this.obs(id_sat_obs, e)),16, numel(id_rin_col));
                            txt = sprintf('%s%c%02d%s\n', txt, ss, prn, str_obs(:)');
                        end
                    end
                end
                fprintf(fid, '%s', txt);
                txt = [];
                this.w_bar.go(e);
            end
            fclose(fid);
            this.log.newLine()
            this.log.addMarkedMessage(sprintf('Receiver exported successifully into: %s', file_name));
        end
        
        function pushResult(this)
            this.parent.out.injectResult(this);
        end
        
        function cropIdSync4out(this, crop_left, crop_right)
            % crop the idsync to export only epochs that are included in the setted out bound
            %
            % SYNTAX:
            % this.cropIdSync4out(crop_left, crop_right)
            if ~isempty(this.out_start_time)
                id_sync = this.getIdSync();
                time = this.getTime();
                keep_idx = [];
                if crop_left && crop_right
                    keep_idx = time > this.out_start_time & time < this.out_stop_time;
                elseif crop_left
                    keep_idx = time > this.out_start_time;
                elseif crop_right
                    keep_idx = time < this.out_stop_time;
                end
                if ~isempty(keep_idx)
                    id_sync(~keep_idx)  = [];
                    this.id_sync = id_sync;
                end
            end
        end
        
        function exportMat(this)
            % Export the receiver into a MATLAB file
            %
            % SYNTAX
            %   this.exportMat
            
            for r = 1 : numel(this)
                try
                    % Get time span of the receiver
                    time = this(r).getTime().getEpoch([1 this(r).getTime().length()]);
                    time.toUtc();
                    
                    fname = fullfile(this(r).state.getOutDir(), sprintf('work_%s-session%03d-%s-%s-rec%04d%s', this(r).parent.marker_name, this(r).state.getCurSession, this(r).state.getSessionsStart.toString('yyyymmdd_HHMMSS'), this(r).state.getSessionsStop.toString('yyyymmdd_HHMMSS'), r, '.mat'));
                    
                    rec = this(r).parent;
                    tmp_out = rec.out; % back-up current out
                    rec.out = Receiver_Output(this(r).cc, this.parent);
                    save(fname, 'rec');
                    rec.out = tmp_out;
                    
                    rec.log.addStatusOk(sprintf('Receiver workspace %s: %s', rec.getMarkerName4Ch, fname));
                catch ex
                    this(r).log.addError(sprintf('Saving receiver workspace %s in matlab format failed: %s', this(r).parent.getMarkerName4Ch, ex.message));
                end
            end
        end
    end
    
    
    % ==================================================================================================================================================
    %% METHODS UTILITIES
    % ==================================================================================================================================================
    
    methods (Access = public, Static)
        
        function [pr, sigma_pr] = smoothCodeWithDoppler(pr, sigma_pr, pr_go_id, dp, sigma_dp, dp_go_id)
            % NOT WORKING due to iono
            % Smooth code with phase (aka estimate phase ambiguity and remove it)
            % Pay attention that the bias between phase and code is now eliminated
            % At the moment the sigma of the solution = sigma of phase
            %
            % SYNTAX
            %   [pr, sigma_ph] = smoothCodeWithDoppler(pr, sigma_pr, pr_go_id, ph, sigma_ph, ph_go_id, cs_mat)
            %
            % EXAMPLE
            %   [pr.obs, pr.sigma] = Receiver.smoothCodeWithDoppler(zero2nan(pr.obs), pr.sigma, pr.go_id, ...
            %                                                       zero2nan(dp.obs), dp.sigma, dp.go_id);
            %
            
            for s = 1 : numel(dp_go_id)
                s_c = find(pr_go_id == dp_go_id(s));
                pr(isnan(dp(:,s)), s_c) = nan;
                
                lim = getOutliers(~isnan(pr(:,s)));
                for l = 1 : size(lim, 1)
                    id_arc = (lim(l,1) : lim(l,2))';
                    
                    len_a = length(id_arc);
                    A = [speye(len_a); [-speye(len_a - 1) sparse(len_a - 1, 1)] + [sparse(len_a - 1, 1) speye(len_a - 1)]];
                    Q = speye(2 * len_a - 1);
                    Q = spdiags([ones(len_a,1) * sigma_pr(s_c).^2; ones(len_a-1,1) * (2 * sigma_dp(s).^2)], 0, Q);
                    Tn = A'/Q;
                    data_tmp = [pr(id_arc, s_c); dp(id_arc, s)];
                    pr(id_arc, s) = (Tn*A)\Tn * data_tmp;
                end
            end
        end
        
        function [ph, sigma_ph] = smoothCodeWithPhase(pr, sigma_pr, pr_go_id, ph, sigma_ph, ph_go_id, cs_mat)
            % NOT WORKING when iono is present
            % Smooth code with phase (aka estimate phase ambiguity and remove it)
            % Pay attention that the bias between phase and code is now eliminated
            % At the moment the sigma of the solution = sigma of phase
            %
            % SYNTAX
            %   [ph, sigma_ph] = smoothCodeWithPhase(pr, sigma_pr, pr_go_id, ph, sigma_ph, ph_go_id, cs_mat)
            %
            % EXAMPLE
            %   [ph.obs, ph.sigma] = Receiver.smoothCodeWithPhase(zero2nan(pr.obs), pr.sigma, pr.go_id, ...
            %                                                   zero2nan(ph.obs), ph.sigma, ph.go_id, ph.cycle_slip);
            %
            
            for s = 1 : numel(ph_go_id)
                s_c = find(pr_go_id == ph_go_id(s));
                pr(isnan(ph(:,s)), s_c) = nan;
                
                lim = getOutliers(~isnan(ph(:,s)), cs_mat(:,s));
                for l = 1 : size(lim, 1)
                    id_arc = (lim(l,1) : lim(l,2))';
                    
                    len_a = length(id_arc);
                    A = [speye(len_a); [-speye(len_a - 1) sparse(len_a - 1, 1)] + [sparse(len_a - 1, 1) speye(len_a - 1)]];
                    Q = speye(2 * len_a - 1);
                    Q = spdiags([ones(len_a,1) * sigma_pr(s_c).^2; ones(len_a-1,1) * (2 * sigma_ph(s).^2)], 0, Q);
                    Tn = A'/Q;
                    data_tmp = [pr(id_arc, s_c); diff(ph(id_arc, s))];
                    ph(id_arc, s) = (Tn*A)\Tn * data_tmp;
                end
            end
        end
        
        function [smt, iono_mf] = ionoCodePhaseSmt(pr_mat, var_pr, ph_mat, var_ph, amb_idx_mat, var_smt, el_rad)
            % Smooth code (GF) observations with carrier phase (GF)
            % to produce a smooth estimation for the ionosphere
            % the smootheness is defined by parameter sigma_smt
            %
            % SYNTAX
            %    [smt, iono_mf_mat] = ionoCodePhaseSmt(pr, sigma_pr, ph, sigma_ph, amb_idx, sigma_smt)
            inan = isnan(ph_mat) | isnan(pr_mat);
            smt = zeros(size(ph_mat));
            n_sat = size(ph_mat,2);
            n_iono = size(pr_mat,1);
            iono_shell_height = 350e3;
            iono_mf = 1 ./ sqrt(1 - (GPS_SS.ELL_A / (GPS_SS.ELL_A + iono_shell_height) .* cos(el_rad)) .^ 2);
            for s = 1 : n_sat
                ph = ph_mat(:,s);
                pr = pr_mat(:,s);
                if sum(~isnan(pr)) > 0
                    amb_idx = amb_idx_mat(:,s);
                    amb_idx = amb_idx - min(amb_idx) + 1;
                    n_amb = max(amb_idx);
                    Apr = [speye(n_iono) sparse(n_iono, n_amb)];
                    Apr(isnan(pr),:) = [];
                    pr(isnan(pr)) = [];
                    Apr = Apr ./var_pr(s);
                    Aamb = zeros(n_iono, n_amb);
                    for i = 1 : n_amb
                        Aamb(:,i) = amb_idx == i;
                    end
                    Aph = [speye(n_iono) sparse(Aamb)];
                    Aph(isnan(ph),:) = [];
                    ph(isnan(ph)) = [];
                    Aph = Aph ./var_ph(s);
                    diag = [ones(n_iono-1,1) -ones(n_iono-1,1)];
                    Adiff = [spdiags(diag,[0 1],n_iono-1,n_iono)  sparse(n_iono-1,n_amb)];
                    Adiff = Adiff ./ var_smt;
                    A = [Apr; Aph; Adiff];
                    y  = [pr ./ var_pr(s); ph ./ var_ph(s); diff(iono_mf(:,s)) ./ var_smt];
                    x = A \ y;
                    % the system is undifferenced
                    % ambiguities are estimated but not used
                    smt(:,s) = x(1 : (end - n_amb));
                else
                    smt(:,s) = ph;
                end
            end
            smt(inan) = nan;
        end
        
        function z_iono = applyMF(obs, mf, reg_alpha)
            % apply a mapping function by LS computation
            % (with regularization)
            %
            % SYNTAX:
            %   z_iono = applyMF(obs, mf, reg_alpha)
            
            if nargin <3 || isempty(reg_alpha)
                reg_alpha = 1;
            end
            
            z_iono = obs;
            idx_nan = (obs == 0) | (isnan(obs));
            
            for s = 1 : size(obs,2)
                if any(~idx_nan(:,s))
                    sat_obs = obs(:, s);
                    mf_sat = mf(:, s);
                    n_obs = size(mf_sat, 1);
                    
                    A =     [sparse(ones(n_obs,1))  spdiags(mf_sat, 0, n_obs, n_obs)];
                    A_reg = [sparse(n_obs,1) (spdiags(ones(size(mf_sat)), 0, n_obs, n_obs) - spdiags(ones(size(mf_sat)), 1, n_obs, n_obs)) * reg_alpha];
                    
                    tmp  = [A(~idx_nan(:,s),:); A_reg] \ sparse([sat_obs(~idx_nan(:,s)); zeros(size(sat_obs))]); tmp(1:3);
                    
                    z_iono(:, s) = tmp(2 : end) + tmp(1);
                end
            end
            z_iono(idx_nan) = 0;
        end
        
        function obs_num = obsCode2Num(obs_code)
            % Convert a 3 char name into a numeric value (float)
            % SYNTAX
            %   obs_num = obsCode2Num(obs_code);
            obs_num = Core_Utils.code3Char2Num(obs_code(:,1:3));
        end
        
        function obs_code = obsNum2Code(obs_num)
            % Convert a numeric value (float) of an obs_code into a 3 char marker
            % SYNTAX
            %   obs_code = obsNum2Code(obs_num)
            obs_code = Core_Utils.num2Code3Char(obs_num);
        end
        
        function marker_num = markerName2Num(marker_name)
            % Convert a 4 char name into a numeric value (float)
            % SYNTAX
            %   marker_num = markerName2Num(marker_name);
            marker_num = Core_Utils.code4Char2Num(marker_name(:,1:4));
        end
        
        function marker_name = markerNum2Name(marker_num)
            % Convert a numeric value (float) of a station into a 4 char marker
            % SYNTAX
            %   marker_name = markerNum2Name(marker_num)
            marker_name = Core_Utils.num2Code4Char(marker_num);
        end
        
        function [y0, pc, wl, ref] = prepareY0(trg, mst, lambda, pivot)
            % prepare y0 and pivot_correction arrays (phase only)
            % SYNTAX [y0, pc] = prepareY0(trg, mst, lambda, pivot)
            % WARNING: y0 contains also the pivot observations and must be reduced by the pivot corrections
            %          use composeY0 to do it
            y0 = [];
            wl = [];
            pc = [];
            i = 0;
            for t = 1 : trg.n_epo
                for f = 1 : trg.n_freq
                    sat_pr = trg.p_range(t,:,f) & mst.p_range(t,:,f);
                    sat_ph = trg.phase(t,:,f) & mst.phase(t,:,f);
                    sat = sat_pr & sat_ph;
                    pc_epo = (trg.phase(t, pivot(t), f) - mst.phase(t, pivot(t), f));
                    y0_epo = ((trg.phase(t, sat, f) - mst.phase(t, sat, f)));
                    ref = median((trg.phase(t, sat, f) - mst.phase(t, sat, f)));
                    wl_epo = lambda(sat, 1);
                    
                    idx = i + (1 : numel(y0_epo))';
                    y0(idx) = y0_epo;
                    pc(idx) = pc_epo;
                    wl(idx) = wl_epo;
                    i = idx(end);
                end
            end
        end
        
        function y0 = composeY0(y0, pc, wl)
            % SYNTAX y0 = composeY0(y0, pc, wl)
            y0 = serialize((y0 - pc) .* wl);
            y0(y0 == 0) = []; % remove pivots
        end
        
        
        function sync(rec, rate)
            % keep epochs at a certain rate for a certain constellation
            %
            % SYNTAX
            %   this.keep(rate, sys_list)
            if nargin > 1 && ~isempty(rate)
                [~, id_sync] = Receiver_Commons.getSyncTimeExpanded(rec, rate);
            else
                [~, id_sync] = Receiver_Commons.getSyncTimeExpanded(rec);
            end
            % Keep the epochs in common
            % starting from the first when all the receivers are available
            % ending whit the last when all the receivers are available
            id_sync((find(sum(isnan(id_sync), 2) == 0, 1, 'first') : find(sum(isnan(id_sync), 2) == 0, 1, 'last')), :);
            
            % keep only synced epochs
            for r = 1 : numel(rec)
                rec(r).keepEpochs(id_sync(~isnan(id_sync(:, r)), r));
            end
            
        end
        
        function [res_ph1, mean_res, var_res] = legacyGetResidualsPh1(res_bin_file_name)
            %res_code1_fix  = [];                      % double differences code residuals (fixed solution)
            %res_code2_fix  = [];                      % double differences code residuals (fixed solution)
            %res_phase1_fix = [];                      % phase differences phase residuals (fixed solution)
            %res_phase2_fix = [];                      % phase differences phase residuals (fixed solution)
            %res_code1_float  = [];                    % double differences code residuals (float solution)
            %res_code2_float  = [];                    % double differences code residuals (float solution)
            res_phase1_float = [];                     % phase differences phase residuals (float solution)
            %res_phase2_float = [];                    % phase differences phase residuals (float solution)
            %outliers_code1 = [];                      % code double difference outlier? (fixed solution)
            %outliers_code2 = [];                      % code double difference outlier? (fixed solution)
            %outliers_phase1 = [];                     % phase double difference outlier? (fixed solution)
            %outliers_phase2 = [];                     % phase double difference outlier? (fixed solution)
            % observations reading
            log = Core.getLogger();
            log.addMessage(['Reading: ' File_Name_Processor.getFileName(res_bin_file_name)]);
            d = dir(res_bin_file_name);
            fid_sat = fopen(res_bin_file_name,'r+');       % file opening
            num_sat = fread(fid_sat, 1, 'int8');                            % read number of satellites
            num_bytes = d.bytes-1;                                          % file size (number of bytes)
            num_words = num_bytes / 8;                                      % file size (number of words)
            num_packs = num_words / (2*num_sat*6);                          % file size (number of packets)
            buf_sat = fread(fid_sat,num_words,'double');                    % file reading
            fclose(fid_sat);                                                % file closing
            %res_code1_fix    = [res_code1_fix    zeros(num_sat,num_packs)]; % observations concatenation
            %res_code2_fix    = [res_code2_fix    zeros(num_sat,num_packs)];
            %res_phase1_fix   = [res_phase1_fix   zeros(num_sat,num_packs)];
            %res_phase2_fix   = [res_phase2_fix   zeros(num_sat,num_packs)];
            %res_code1_float  = [res_code1_float  zeros(num_sat,num_packs)];
            %res_code2_float  = [res_code2_float  zeros(num_sat,num_packs)];
            res_phase1_float = [res_phase1_float zeros(num_sat,num_packs)];
            %res_phase2_float = [res_phase2_float zeros(num_sat,num_packs)];
            %outliers_code1   = [outliers_code1   zeros(num_sat,num_packs)];
            %outliers_code2   = [outliers_code2   zeros(num_sat,num_packs)];
            %outliers_phase1  = [outliers_phase1  zeros(num_sat,num_packs)];
            %outliers_phase2  = [outliers_phase2  zeros(num_sat,num_packs)];
            i = 0;                                                           % epoch counter
            for j = 0 : (2*num_sat*6) : num_words-1
                i = i+1;                                                     % epoch counter increase
                %res_code1_fix(:,i)    = buf_sat(j + [1:num_sat]);            % observations logging
                %res_code2_fix(:,i)    = buf_sat(j + [1*num_sat+1:2*num_sat]);
                %res_phase1_fix(:,i)   = buf_sat(j + [2*num_sat+1:3*num_sat]);
                %res_phase2_fix(:,i)   = buf_sat(j + [3*num_sat+1:4*num_sat]);
                %res_code1_float(:,i)  = buf_sat(j + [4*num_sat+1:5*num_sat]);
                %res_code2_float(:,i)  = buf_sat(j + [5*num_sat+1:6*num_sat]);
                res_phase1_float(:,i) = buf_sat(j + (6*num_sat+1:7*num_sat));
                %res_phase2_float(:,i) = buf_sat(j + [7*num_sat+1:8*num_sat]);
                %outliers_code1(:,i)   = buf_sat(j + [8*num_sat+1:9*num_sat]);
                %outliers_code2(:,i)   = buf_sat(j + [9*num_sat+1:10*num_sat]);
                %outliers_phase1(:,i)  = buf_sat(j + [10*num_sat+1:11*num_sat]);
                %outliers_phase2(:,i)  = buf_sat(j + [11*num_sat+1:12*num_sat]);
            end
            res_ph1 = res_phase1_float';
            mean_res = mean(mean(zero2nan(res_ph1'), 'omitnan'), 'omitnan');
            var_res = max(var(zero2nan(res_ph1'), 'omitnan'));
        end
    end
    %% METHODS PLOTTING FUNCTIONS
    % ==================================================================================================================================================
    
    % Various debug images
    % name variant:
    %   c cartesian
    %   s scatter
    %   p polar
    %   m mixed
    methods (Access = public)
        
        function showAll(this)
            this.toString;
            this.showDataAvailability();
            this.showSNR_p();
            this.showDt();
            this.showAll@Receiver_Commons();
        end
        
        function showDt(this)
            % Plot Clock error
            %
            % SYNTAX
            %   this.plotDt
            
            rec = this;
            if ~isempty(rec)
                f = figure; f.Name = sprintf('%03d: Dt Err', f.Number); f.NumberTitle = 'off';
                t = rec.time.getEpoch(this.getIdSync).getMatlabTime();
                nans = zero2nan(double(~rec.getMissingEpochs()));
                plot(t, rec.getDesync .* nans(this.getIdSync), '-k', 'LineWidth', 2);
                hold on;
                plot(t, rec.getDtPr .* nans(this.getIdSync), ':', 'LineWidth', 2);
                plot(t, rec.getDtPh .* nans(this.getIdSync), ':', 'LineWidth', 2);
                plot(t, (rec.getDtPrePro - rec.getDtPr) .* nans(this.getIdSync), '-', 'LineWidth', 2);
                plot(t, rec.getDtPrePro .* nans(this.getIdSync), '-', 'LineWidth', 2);
                if any(rec.getDt)
                    plot(t, rec.getDt .* nans(this.getIdSync), '-', 'LineWidth', 2);
                    plot(t, rec.getTotalDt .* nans(this.getIdSync), '-', 'LineWidth', 2);
                    legend('desync time', 'dt pre-estimated from pseudo ranges', 'dt pre-estimated from phases', 'dt correction from LS on Code', 'dt estimated from pre-processing', 'residual dt from carrier phases', 'total dt', 'Location', 'NorthEastOutside');
                else
                    legend('desync time', 'dt pre-estimated from pseudo ranges', 'dt pre-estimated from phases', 'dt correction from LS on Code', 'dt estimated from pre-processing', 'Location', 'NorthEastOutside');
                end
                xlim([t(1) t(end)]); setTimeTicks(4,'dd/mm/yyyy HH:MMPM'); h = ylabel('receiver clock error [s]'); h.FontWeight = 'bold';
                h = title(sprintf('dt - receiver %s', rec.parent.marker_name),'interpreter', 'none'); h.FontWeight = 'bold'; %h.Units = 'pixels'; h.Position(2) = h.Position(2) + 8; h.Units = 'data';
            end
        end
        
        function showResPerSat(this, res, sys_c_list)
            % Plot the residuals of phase per Satellite
            % 
            % INPUT
            %   res     is the matrix of residuals and can be passed from e.g. NET
            %
            % SYNTAX 
            %   this.showResPerSat(res)
            
            if nargin < 3
                sys_c_list = unique(this.system);
            end
            if nargin < 2
                res = this.sat.res;
            end
            f = figure; f.Name = sprintf('%03d: CS, Outlier', f.Number); f.NumberTitle = 'off';
            ss_ok = intersect(this.cc.sys_c, sys_c_list);
            for sys_c = sys_c_list
                ss_id = find(this.cc.sys_c == sys_c);
                switch numel(ss_ok)
                    case 2
                        subplot(1,2, ss_id);
                    case 3
                        subplot(2,2, ss_id);
                    case 4
                        subplot(2,2, ss_id);
                    case 5
                        subplot(2,3, ss_id);
                    case 6
                        subplot(2,3, ss_id);
                    case 7
                        subplot(2,4, ss_id);
                end
                
                ep = repmat((1: this.time.length)',1, size(this.sat.outliers_ph_by_ph, 2));
                
                for prn = this.cc.prn(this.cc.system == sys_c)'
                    go_id = this.getGoId(sys_c, prn);
                    s = find(unique(this.go_id(this.obs_code(:,1) == 'L')) == go_id);
                    if any(s)
                        id_ok = find(~isnan(zero2nan(res(:, go_id))));
                        [~, id_sort] = sort(abs(res(id_ok, go_id)));
                        scatter(id_ok(id_sort),  prn * ones(size(id_ok)), 50, 1e3 * (res(id_ok(id_sort), go_id)), 'filled');
                        hold on
                    end
                end
                cax = caxis(); caxis([-1 1] * max(abs(cax)));
                colormap(gat);
                if min(abs(cax)) > 5
                    setColorMapGat(caxis(), 0.99, [-5 5])
                end
                colorbar; ax = gca; ax.Color = [0.7 0.7 0.7];
                prn_ss = unique(this.prn(this.system == sys_c));
                xlim([1 size(this.obs,2)]);
                ylim([min(prn_ss) - 1 max(prn_ss) + 1]);
                h = ylabel('PRN'); h.FontWeight = 'bold';
                ax = gca(); ax.YTick = prn_ss;
                grid on;
                h = xlabel('epoch'); h.FontWeight = 'bold';
                h = title(sprintf('%s %s Residuals per sat [mm]', this.cc.getSysName(sys_c), this.parent.marker_name), 'interpreter', 'none'); h.FontWeight = 'bold';
            end
        end
        
        function showOutliersAndCycleSlip(this, sys_c_list)
            % Plot the outliers found
            % SYNTAX this.showOutliersAndCycleSlip(sys_c_list)
            
            if nargin == 1
                sys_c_list = unique(this.system);
            end
            f = figure; f.Name = sprintf('%03d: CS, Outlier', f.Number); f.NumberTitle = 'off';
            ss_ok = intersect(this.cc.sys_c, sys_c_list);
            for sys_c = sys_c_list
                ss_id = find(this.cc.sys_c == sys_c);
                switch numel(ss_ok)
                    case 2
                        subplot(1,2, ss_id);
                    case 3
                        subplot(2,2, ss_id);
                    case 4
                        subplot(2,2, ss_id);
                    case 5
                        subplot(2,3, ss_id);
                    case 6
                        subplot(2,3, ss_id);
                    case 7
                        subplot(2,4, ss_id);
                end
                
                ep = repmat((1: this.time.length)',1, size(this.sat.outliers_ph_by_ph, 2));
                
                for prn = this.cc.prn(this.cc.system == sys_c)'
                    id_ok = find(any(this.obs((this.system == sys_c)' & this.prn == prn, :),1));
                    plot(id_ok, prn * ones(size(id_ok)), 's', 'Color', [0.8 0.8 0.8]);
                    hold on;
                    id_ok = find(any(this.obs((this.system == sys_c)' & this.prn == prn & this.obs_code(:,1) == 'L', :),1));
                    plot(id_ok, prn * ones(size(id_ok)), '.', 'Color', [0.7 0.7 0.7]);
                    s = find(this.go_id(this.obs_code(:,1) == 'L') == this.getGoId(sys_c, prn));
                    if any(s)
                        cs = ep(this.sat.cicle_slip_ph_by_ph(:, s) ~= 0);
                        plot(cs,  prn * ones(size(cs)), '.k', 'MarkerSize', 20)
                        out = ep(this.sat.outliers_ph_by_ph(:, s) ~= 0);
                        plot(out,  prn * ones(size(out)), '.', 'MarkerSize', 20, 'Color', [1 0.4 0]);
                    end
                end
                prn_ss = unique(this.prn(this.system == sys_c));
                xlim([1 size(this.obs,2)]);
                ylim([min(prn_ss) - 1 max(prn_ss) + 1]);
                h = ylabel('PRN'); h.FontWeight = 'bold';
                ax = gca(); ax.YTick = prn_ss;
                grid on;
                h = xlabel('epoch'); h.FontWeight = 'bold';
                h = title(sprintf('%s %s cycle-slip(k) & outlier(o)', this.cc.getSysName(sys_c), this.parent.marker_name), 'interpreter', 'none'); h.FontWeight = 'bold';
            end
        end
        
        function showOutliersAndCycleSlip_d(this, sys_c_list)
            % Plot the outliers found
            % SYNTAX this.showOutliersAndCycleSlip_d(sys_c_list)
            
            if nargin == 1
                sys_c_list = unique(this.system);
            end
            f = figure; f.Name = sprintf('%03d: CS, Outlier', f.Number); f.NumberTitle = 'off';
            ss_ok = intersect(this.cc.sys_c, sys_c_list);
            
            [ph, id_ph] = this.getObs('L');
            wl = this.wl(id_ph);
            ph = bsxfun(@times, zero2nan(ph), wl)';

            phs = this.synt_ph;
            cs = this.sat.cicle_slip_ph_by_ph;
            out = this.sat.outliers_ph_by_ph;
            for sys_c = sys_c_list
                ss_id = find(this.cc.sys_c == sys_c);
                switch numel(ss_ok)
                    case 2
                        subplot(1,2, ss_id);
                    case 3
                        subplot(2,2, ss_id);
                    case 4
                        subplot(2,2, ss_id);
                    case 5
                        subplot(2,3, ss_id);
                    case 6
                        subplot(2,3, ss_id);
                    case 7
                        subplot(2,4, ss_id);
                end
                
                ep = repmat((1: this.time.length)',1, size(this.sat.outliers_ph_by_ph, 2));
                                
                id_ss = find(this.system(id_ph) == sys_c);
                dph_diff = Core_Utils.diffAndPred(bsxfun(@rdivide, ph(:,id_ss) - phs(:,id_ss), wl(id_ss)'));
                dph_diff = (bsxfun(@rdivide, ph(:,id_ss) - phs(:,id_ss), wl(id_ss)'));
                plot(dph_diff, 'Color', [0.7 0.7 0.7]); hold on;
                % fopr each sat visualize outliers and CS
                for s = 1 : numel(id_ss)
                    id_out = find(out(:, id_ss(s)));
                    plot(id_out, dph_diff(id_out, s), '.', 'MarkerSize', 20, 'Color', [1 0.4 0]);
                    id_cs = find(cs(:, id_ss(s)));
                    plot(id_cs, dph_diff(id_cs, s), '.k', 'MarkerSize', 20);
                end
                grid on;
                h = xlabel('epoch'); h.FontWeight = 'bold';
                h = title(sprintf('%s %s cycle-slip(k) & outlier(o)', this.cc.getSysName(sys_c), this.parent.marker_name), 'interpreter', 'none'); h.FontWeight = 'bold';
            end
        end
        
        function showOutliersAndCycleSlip_p(this, sys_c_list)
            % Plot Signal to Noise Ration in a skyplot
            % SYNTAX this.showOutliersAndCycleSlip_p(sys_c_list)
            
            % SNRs
            if nargin == 1
                sys_c_list = unique(this.system);
            end
            
            for sys_c = sys_c_list
                [~, ~, ph_id] = this.getPhases(sys_c);
                f = figure; f.Name = sprintf('%03d: CS, Out %s', f.Number, sys_c); f.NumberTitle = 'off';
                polarScatter([],[],1,[]);
                hold on;
                decl_n = (serialize(90 - this.sat.el(:, this.go_id(ph_id))) / 180*pi) / (pi/2);
                x = sin(serialize(this.sat.az(:, this.go_id(ph_id))) / 180 * pi) .* decl_n; x(serialize(this.sat.az(:, this.go_id(ph_id))) == 0) = [];
                y = cos(serialize(this.sat.az(:, this.go_id(ph_id))) / 180 * pi) .* decl_n; y(serialize(this.sat.az(:, this.go_id(ph_id))) == 0) = [];
                plot(x, y, '.', 'Color', [0.8 0.8 0.8]); % all sat
                decl_n = (serialize(90 - this.sat.el(this.id_sync(:), this.go_id(ph_id))) / 180*pi) / (pi/2);
                x = sin(serialize(this.sat.az(this.id_sync(:), this.go_id(ph_id))) / 180 * pi) .* decl_n; x(serialize(this.sat.az(this.id_sync(:), this.go_id(ph_id))) == 0) = [];
                y = cos(serialize(this.sat.az(this.id_sync(:), this.go_id(ph_id))) / 180 * pi) .* decl_n; y(serialize(this.sat.az(this.id_sync(:), this.go_id(ph_id))) == 0) = [];
                m = serialize(~isnan(zero2nan(this.obs(ph_id, this.id_sync(:)))')); m(serialize(this.sat.az(this.id_sync(:), this.go_id(ph_id))) == 0) = [];
                plot(x(m), y(m), '.', 'Color', [0.4 0.4 0.4]); % sat in vew
                decl_n = (serialize(90 - this.sat.el(:, this.go_id(ph_id))) / 180*pi) / (pi/2);
                x = sin(serialize(this.sat.az(:, this.go_id(ph_id))) / 180 * pi) .* decl_n; x(serialize(this.sat.az(:, this.go_id(ph_id))) == 0) = [];
                y = cos(serialize(this.sat.az(:, this.go_id(ph_id))) / 180 * pi) .* decl_n; y(serialize(this.sat.az(:, this.go_id(ph_id))) == 0) = [];
                cut_offed = decl_n(serialize(this.sat.az(:, this.go_id(ph_id))) ~= 0) > ((90 - this.state.getCutOff) / 90);
                plot(x(cut_offed), y(cut_offed), '.', 'Color', [0.95 0.95 0.95]);
                
                for s = unique(this.go_id(ph_id))'
                    az = this.sat.az(:,s);
                    el = this.sat.el(:,s);
                    
                    id_cs = find(this.go_id(this.obs_code(:,1) == 'L') == s);
                    cs = sum(this.sat.cicle_slip_ph_by_ph(:, id_cs), 2) > 0;
                    out = sum(this.sat.outliers_ph_by_ph(:, id_cs), 2) > 0;
                    
                    decl_n = (serialize(90 - el(cs)) / 180*pi) / (pi/2);
                    x = sin(az(cs)/180*pi) .* decl_n; x(az(cs) == 0) = [];
                    y = cos(az(cs)/180*pi) .* decl_n; y(az(cs) == 0) = [];
                    plot(x, y, '.k', 'MarkerSize', 20)
                    
                    decl_n = (serialize(90 - el(out)) / 180*pi) / (pi/2);
                    x = sin(az(out)/180*pi) .* decl_n; x(az(out) == 0) = [];
                    y = cos(az(out)/180*pi) .* decl_n; y(az(out) == 0) = [];
                    plot(x, y, '.', 'MarkerSize', 20, 'Color', [1 0.4 0]);
                end
                h = title(sprintf('%s %s cycle-slip(k) & outlier(o)', this.cc.getSysName(sys_c), this.parent.marker_name), 'interpreter', 'none'); h.FontWeight = 'bold';
            end
            
        end
        
        function showDataAvailability(this, sys_c, band)
            % Plot all the satellite seen by the system
            % SYNTAX this.plotDataAvailability(sys_c)
            
            if (nargin == 1)
                sys_c = this.cc.sys_c;
            end
            f = figure; f.Name = sprintf('%03d: DataAvail', f.Number); f.NumberTitle = 'off';
            ss_ok = intersect(this.cc.sys_c, sys_c);
            for ss = ss_ok
                ss_id = find(this.cc.sys_c == ss);
                switch numel(ss_ok)
                    case 2
                        subplot(1,2, ss_id);
                    case 3
                        subplot(2,2, ss_id);
                    case 4
                        subplot(2,2, ss_id);
                    case 5
                        subplot(2,3, ss_id);
                    case 6
                        subplot(2,3, ss_id);
                    case 7
                        subplot(2,4, ss_id);
                end
                
                for prn = this.cc.prn(this.cc.system == ss)'
                    if nargin > 2
                        band_id = this.obs_code(:,2) == this.cc.getSys(ss).CODE_RIN3_2BAND(band);
                    else
                        band_id = true(size(this.prn ));
                    end
                    id_ok = find(any(this.obs((this.system == ss)' & this.prn == prn & band_id, :),1));
                    plot(id_ok, prn * ones(size(id_ok)), 's', 'Color', [0.8 0.8 0.8]);
                    hold on;
                    id_ok = find(any(this.obs((this.system == ss)' & this.prn == prn & this.obs_code(:,1) == 'C' & band_id, :),1));
                    plot(id_ok, prn * ones(size(id_ok)), 'o', 'Color', [0.2 0.2 0.2]);
                    hold on;
                    id_ok = find(any(this.obs((this.system == ss)' & this.prn == prn & this.obs_code(:,1) == 'L' & band_id, :),1));
                    plot(id_ok, prn * ones(size(id_ok)), '.');
                end
                prn_ss = unique(this.prn(this.system == ss));
                xlim([1 size(this.obs,2)]);
                ylim([min(prn_ss) - 1 max(prn_ss) + 1]);
                h = ylabel('PRN'); h.FontWeight = 'bold';
                ax = gca(); ax.YTick = prn_ss;
                grid on;
                h = xlabel('epoch'); h.FontWeight = 'bold';
                title(this.cc.getSysName(ss));
            end
        end
        
        function showObsVsSynt_m(this, sys_c)
            % Plots phases and pseudo-ranges aginst their synthesised values
            % SYNTAX
            %   this.plotVsSynt_m(<sys_c>)
            
            % Phases
            if nargin == 1
                [ph, ~, id_ph] = this.getPhases;
                sensor_ph = Core_Utils.diffAndPred(ph - this.getSyntPhases); sensor_ph = bsxfun(@minus, sensor_ph, median(sensor_ph, 2, 'omitnan'));
                f = figure; f.Name = sprintf('%03d: VsSynt', f.Number); f.NumberTitle = 'off';
            else
                [ph, ~, id_ph] = this.getPhases(sys_c);
                sensor_ph = Core_Utils.diffAndPred(ph - this.getSyntPhases(sys_c)); sensor_ph = bsxfun(@minus, sensor_ph, median(sensor_ph, 2, 'omitnan'));
                f = figure; f.Name = sprintf('%03d: VsSynt%s', f.Number, this.cc.getSysName(sys_c)); f.NumberTitle = 'off';
            end
            
            subplot(2,3,1); plot(sensor_ph); title('Phases observed vs synthesised');
            
            this.updateAzimuthElevation()
            id_ok = (~isnan(sensor_ph));
            az = this.sat.az(:,this.go_id(id_ph));
            el = this.sat.el(:,this.go_id(id_ph));
            %flag = flagExpand(abs(sensor1(id_ok)) > 0.2, 1);
            h1 = subplot(2,3,3);  polarScatter(serialize(az(id_ok))/180*pi,serialize(90-el(id_ok))/180*pi, 30, serialize(sensor_ph(id_ok)), 'filled');
            caxis([-1 1]); colormap(gat); setColorMapGat([-1 1], 0.8, [-0.15 0.15]); colorbar();
            subplot(2,3,2); scatter(serialize(az(id_ok)), serialize(el(id_ok)), 50, abs(serialize(sensor_ph(id_ok))) > 0.2, 'filled'); caxis([-1 1]);
            
            % Pseudo Ranges
            [pr, id_pr] = this.getPseudoRanges;
            sensor_pr = Core_Utils.diffAndPred(pr - this.getSyntPrObs); sensor_pr = bsxfun(@minus, sensor_pr, median(sensor_pr, 2, 'omitnan'));
            subplot(2,3,4); plot(sensor_pr); title('Pseudo-ranges observed vs synthesised');
            
            id_ok = (~isnan(sensor_pr));
            az = this.sat.az(:,this.go_id(id_pr));
            el = this.sat.el(:,this.go_id(id_pr));
            %flag = flagExpand(abs(sensor1(id_ok)) > 0.2, 1);
            h1 = subplot(2,3,6); polarScatter(serialize(az(id_ok))/180*pi,serialize(90-el(id_ok))/180*pi, 30, serialize(sensor_pr(id_ok)), 'filled');
            caxis([-20 20]); colorbar();
            subplot(2,3,5); scatter(serialize(az(id_ok)), serialize(el(id_ok)), 50, abs(serialize(sensor_pr(id_ok))) > 5, 'filled');
            caxis([-1 1]);
        end
        
        function showObsStats(this)
            % Show statistics about the observations stored in the object
            %
            % SYNTAX
            %   this.showObsStats()
            
            % CODE
            [pr, id_pr] = this.getPseudoRanges();
            id_pr = find(id_pr);
            prs = this.getSyntPrObs();
            pr_diff = zero2nan(pr) - zero2nan(prs);
            %figure; plot(pr_diff,'.');
            %title('Pr) observations - synth')
            %dockAllFigures;
            
            % remove phases clock
            dt_pr = cumsum(median(Core_Utils.diffAndPred(zero2nan(pr)-zero2nan(prs)), 2, 'omitnan'));
            
            id = (1 : numel(dt_pr))';
            dt_pr_drift = Core_Utils.interp1LS(id, dt_pr, 3, id);
            dt_pr = dt_pr - dt_pr_drift;
            %ckfh = figure; plot(dt_pr); hold on; plot(dt_pr_drift);
            %title('Pr) clock from observations')
            %hold on; plot(dt_pr, 'k');
            %legend('clock', 'drifting', 'final clock');
            
            pr_diff = bsxfun(@minus, pr_diff, dt_pr);
            %figure; plot(pr_diff,'.');
            %title('Pr) observations - synth (no clock)')
            %dockAllFigures;
            
            % remove outliers and CS
            id_ko = flagExpand(abs(Core_Utils.diffAndPred(pr_diff,1)) > 10 | abs(Core_Utils.diffAndPred(pr_diff,2)) > 20, 1);
            pr_diff(id_ko) = nan;
            
            % statistics
            sensor_pr = Core_Utils.diffAndPred(pr_diff,2);
            
            % PHASES
            [ph, wl, id_ph] = this.getPhases();
            id_ph = find(id_ph);
            phs = this.getSyntPhases();
            ph_diff = zero2nan(ph) - zero2nan(phs);
            %figure; plot(ph_diff,'.');
            %title('Ph) observations - synth')
            %dockAllFigures;
            
            % remove phases clock
            dt_ph = cumsum(median(Core_Utils.diffAndPred(zero2nan(ph)-zero2nan(phs)), 2, 'omitnan'));
            
            id = (1 : numel(dt_ph))';
            dt_ph_drift = Core_Utils.interp1LS(id, dt_ph, 5, id);
            dt_ph = dt_ph - dt_ph_drift;
            %figure(ckfh); plot(dt_ph); hold on; plot(dt_ph_drift);
            %title('Ph) clock from observations')
            %hold on; plot(dt_ph, 'b');
            %legend('pr clock', 'pr drifting', 'pr final clock', 'ph clock', 'ph drifting', 'ph final clock');
            
            ph_diff = bsxfun(@minus, ph_diff, dt_ph);
            %figure; plot(ph_diff,'.');
            %title('Ph) observations - synth (no clock)')
            %dockAllFigures;
            
            % remove outliers and CS
            id_ko = flagExpand(abs(Core_Utils.diffAndPred(ph_diff,1)) > 0.10 | abs(Core_Utils.diffAndPred(ph_diff,2)) > 0.05, 1);
            ph_diff(id_ko) = nan;
            
            % statistics
            sensor_ph = Core_Utils.diffAndPred(ph_diff,2);
            %%
            % for each constellations
            fprintf('\n---------------------------------------------------\n')
            fprintf(' Overall statistics on observations - synthesised\n')
            fprintf('---------------------------------------------------\n')
            sensor_pr0 = pr_diff;
            sensor_ph0 = ph_diff;
            for sys_c = unique(this.system)
                id_ok = this.system(id_ph) == sys_c;
                fprintf('%c) std = %.2f mm - std = %.2f mm\n', sys_c, mean(std(sensor_pr0(:, id_ok)*1e3, 'omitnan'), 'omitnan'), mean(std(sensor_ph0(:, id_ok)*1e3, 'omitnan'), 'omitnan'));
            end
            
            fprintf('\nfirst temporal derivative:\n')
            sensor_pr1 = Core_Utils.diffAndPred(pr_diff,1);
            sensor_ph1 = Core_Utils.diffAndPred(ph_diff,1);
            for sys_c = unique(this.system)
                id_ok = this.system(id_ph) == sys_c;
                fprintf('%c) std = %.2f mm/e - std = %.2f mm/e\n', sys_c, mean(std(sensor_pr1(:, id_ok)*1e3, 'omitnan'), 'omitnan'), mean(std(sensor_ph1(:, id_ok)*1e3, 'omitnan'), 'omitnan'));
            end
            
            fprintf('\nsecond temporal derivative:\n')
            sensor_pr2 = Core_Utils.diffAndPred(pr_diff,2);
            sensor_ph2 = Core_Utils.diffAndPred(ph_diff,2);
            for sys_c = unique(this.system)
                id_ok = this.system(id_ph) == sys_c;
                fprintf('%c) std = %.2f mm/e^2 - std = %.2f mm/e^2\n', sys_c, mean(std(sensor_pr2(:, id_ok)*1e3, 'omitnan'), 'omitnan'), mean(std(sensor_ph2(:, id_ok)*1e3, 'omitnan'), 'omitnan'));
            end
            
            %%
            std_ph_prn = [];
            std_pr_prn = [];
            mean_ph_prn = [];
            mean_pr_prn = [];
            min_ph_prn = [];
            min_pr_prn = [];
            max_ph_prn = [];
            max_pr_prn = [];
            s = 0;
            fprintf('\n');
            fprintf('      |  PR                                       |  PH                                   |\n');
            fprintf('      |-----------------------------------------------------------------------------------|\n');
            fprintf('      |   median  |      std |      min |     max |   median |    std |     min |     max |\n');
            fprintf('      |-----------------------------------------------------------------------------------|\n');
            std_stat = zeros(numel(unique(this.system)), 9, 2); % N const, n bands, pr/ph
            sys_full_name = {};
            for sys_c = unique(this.system)
                sys_full_name = [sys_full_name {this.cc.getSysExtName(sys_c)}];
            end
            for sys_c = unique(this.system)
                s = s + 1;
                figure; clf; hold on;
                id_sys = find(this.system(id_ph) == sys_c);
                prn  = this.prn(id_ph(id_sys));
                band = unique(str2num(this.obs_code(id_ph(id_sys), 2)));
                legend_on = false(max(band), 1);
                legend_s{1} = {};
                legend_s{2} = {};
                for p = unique(prn)'
                    id_prn = find(prn == p);
                    band = str2num(this.obs_code(id_ph(id_sys(id_prn)), 2));
                    for b = unique(band)'
                        id_band = find(band == b);
                        id_obs = id_sys(id_prn(id_band));
                        [v_min, id_min] = min(zero2nan(std(sensor_pr2(:, id_obs),'omitnan')));
                        id_band = id_band(id_min);
                        id_obs = id_sys(id_prn(id_band));
                        mean_ph_prn(prn(id_prn(id_band)), b, s) = (zero2nan(median(sensor_ph0(:, id_obs),'omitnan'))) * 1e3;
                        mean_pr_prn(prn(id_prn(id_band)), b, s) = (zero2nan(median(sensor_pr0(:, id_obs),'omitnan'))) * 1e3;
                        std_ph_prn(prn(id_prn(id_band)), b, s) = (zero2nan(std(sensor_ph2(:, id_obs),'omitnan'))) * 1e3;
                        std_pr_prn(prn(id_prn(id_band)), b, s) = (zero2nan(std(sensor_pr2(:, id_obs),'omitnan'))) * 1e3;
                        min_ph_prn(prn(id_prn(id_band)), b, s) = (min(zero2nan(sensor_ph2(:, id_obs)))) * 1e3;
                        min_pr_prn(prn(id_prn(id_band)), b, s) = (min(zero2nan(sensor_pr2(:, id_obs)))) * 1e3;
                        max_ph_prn(prn(id_prn(id_band)), b, s) = (max(zero2nan(sensor_ph2(:, id_obs)))) * 1e3;
                        max_pr_prn(prn(id_prn(id_band)), b, s) = (max(zero2nan(sensor_pr2(:, id_obs)))) * 1e3;
                        subplot(2,1,1)
                        plot(prn(id_prn(id_band)), std_ph_prn(prn(id_prn(id_band)), b, s), '.', 'MarkerSize', 30, 'Color', Core_UI.getColor(b, 9)); hold on;
                        subplot(2,1,2)
                        plot(prn(id_prn(id_band)), std_pr_prn(prn(id_prn(id_band)), b, s), 'o', 'MarkerSize', 10, 'LineWidth', 3, 'Color', Core_UI.getColor(b, 9)); hold on;
                        obs_code = this.obs_code(id_ph(id_sys(id_prn(id_band))), :);
                        if ~legend_on(b)
                            legend_on(b) = true;
                            legend_s{1} = [legend_s{1} {['PH ' obs_code(1:2)]}];
                            legend_s{2} = [legend_s{2} {['PR ' obs_code(1:2)]}];
                        end
                    end
                end
                subplot(2,1,1)
                legend(legend_s{1});
                subplot(2,1,2)
                legend(legend_s{2});
                %ylim([0 50]);
                h = ylabel('std (mm)'); h.FontWeight = 'bold';
                h = xlabel('PRN'); h.FontWeight = 'bold';
                ax = gca(); ax.XTick = unique(prn);
                
                grid on;
                title([this.cc.getSysExtName(sys_c) ' observations - synthesised (second temporal derivative)']);
                fh = gcf; fh.Name = sprintf('%d %s) %c obs-synth', fh.Number, this.parent.getMarkerName4Ch, sys_c); fh.NumberTitle = 'off';
                
                for b = 1 : size(mean_pr_prn, 2)
                    if ~isnan(mean(zero2nan(mean_pr_prn(:, b, s)), 'omitnan'))
                        fprintf(' %c L%d | %9.2f | %8.2f | %8.2f | %7.2f | %8.2f | %6.2f | %7.2f | %7.2f |\n', ...
                            sys_c(1), b, ...
                            mean(zero2nan(mean_pr_prn(:, b, s)), 'omitnan'), ...
                            mean(zero2nan(std_pr_prn(:, b, s)), 'omitnan'), ...
                            mean(zero2nan(min_pr_prn(:, b, s)), 'omitnan'), ...
                            mean(zero2nan(max_pr_prn(:, b, s)), 'omitnan'), ...
                            mean(zero2nan(mean_ph_prn(:, b, s)), 'omitnan'), ...
                            mean(zero2nan(std_ph_prn(:, b, s)), 'omitnan'), ...
                            min(zero2nan(min_ph_prn(:, b, s))), ...
                            max(zero2nan(max_ph_prn(:, b, s))));
                        std_stat(s, b, 1) = mean(zero2nan(std_pr_prn(:, b, s)), 'omitnan');
                        std_stat(s, b, 2) = mean(zero2nan(std_ph_prn(:, b, s)), 'omitnan');
                    end
                end
            end
            %%
            c = categorical(sys_full_name);
            if numel(c) > 1
                figure; clf; ax = gca; hold on
                ax.ColorOrder = Core_UI.getColor(1:9,9);
                bar(c, std_stat(:,:,1)); title([this.parent.getMarkerName4Ch ' )  pseudo-ranges - synthesised (second temporal derivative)']);
                legend('L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7', 'L8', 'L9', 'Location', 'NorthEastOutside');
                grid on
                ylabel('STD [mm/e^2]')
                fh = gcf; fh.Name = sprintf('%d %s) PR stat obs-synth', fh.Number, this.parent.getMarkerName4Ch); fh.NumberTitle = 'off';
                
                figure; clf; ax = gca; hold on
                ax.ColorOrder = Core_UI.getColor(1:9,9);
                bar(c, std_stat(:,:,2)); title([this.parent.getMarkerName4Ch ' )  phases - synthesised (second temporal derivative)']);
                legend('L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7', 'L8', 'L9', 'Location', 'NorthEastOutside');
                grid on
                ylabel('STD [mm/e^2]')
                fh = gcf; fh.Name = sprintf('%d %s) PH stat obs-synth', fh.Number, this.parent.getMarkerName4Ch); fh.NumberTitle = 'off';
                dockAllFigures
            end
            
            %%
        end
        
        function f_handle = showSNR_p(this, sys_c_list, flag_smooth)
            % Plot Signal to Noise Ration in a skyplot
            % SYNTAX f_handles = this.plotSNR(sys_c)
            
            % SNRs
            if nargin < 2 || isempty(sys_c_list)
                sys_c_list = unique(this.system);
            end
            
            idx_f = 0;
            for sys_c = sys_c_list
                for b = 1 : 9 % try all the bands
                    [snr, snr_id] = this.getSNR(sys_c, num2str(b));
                    if nargin > 2 && flag_smooth
                        snr = Receiver_Commons.smoothSatData([],[],zero2nan(snr), [], 'spline', 900 / this.getRate, 10); % smoothing SNR => to be improved
                    end
                    
                    if any(snr_id) && any(snr(:))
                        idx_f = idx_f +1;
                        f = figure; f.Name = sprintf('%03d: SNR%d %s', f.Number, b, this.cc.getSysName(sys_c)); f.NumberTitle = 'off';
                        f_handle(idx_f) = f;
                        id_ok = (~isnan(snr));
                        az = this.sat.az(:,this.go_id(snr_id));
                        el = this.sat.el(:,this.go_id(snr_id));
                        polarScatter(serialize(az(id_ok))/180*pi,serialize(90-el(id_ok))/180*pi, 45, serialize(snr(id_ok)), 'filled');
                        colormap(jet);  cax = caxis(); caxis([min(cax(1), 10), max(cax(2), 55)]); setColorMap([10 55], 0.9); colorbar();
                        h = title(sprintf('SNR%d - receiver %s - %s', b, this.parent.marker_name, this.cc.getSysExtName(sys_c)),'interpreter', 'none'); h.FontWeight = 'bold'; h.Units = 'pixels'; h.Position(2) = h.Position(2) + 20; h.Units = 'data';
                    end
                end
            end
            
            if idx_f == 0
                f_handle = [];
            end
        end
    end
end
