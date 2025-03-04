%   CLASS Receiver_Commons
% =========================================================================
%
%
%   Class to store receiver common methods and abstract properties
%
% EXAMPLE
%   trg = Receiver_Commons();
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
classdef Receiver_Commons <  matlab.mixin.Copyable
    properties (SetAccess = public, GetAccess = public)
        parent         % habdle to parent object
        
        rid            % receiver interobservation biases
        flag_rid       % clock error for each obs code {num_obs_code}
    end
    
    % ==================================================================================================================================================
    %% PROPERTIES CELESTIAL INFORMATIONS
    % ==================================================================================================================================================
    
    properties (Abstract, SetAccess = public, GetAccess = public)
        sat
    end
    
    % ==================================================================================================================================================
    %% PROPERTIES POSITION
    % ==================================================================================================================================================
    
    properties (SetAccess = public, GetAccess = public)
        xyz            % position of the receiver (XYZ geocentric)
        enu            % position of the receiver (ENU local)
        
        lat            % ellipsoidal latitude
        lon            % ellipsoidal longitude
        h_ellips       % ellipsoidal height
        h_ortho        % orthometric height
        
        add_coo 
%         = struct( ...
%             'coo',      [], ...    % additional estimated coo
%             'time',         [], ...    % time of the coo
%             'rate',          [] ...    % rate of the coo
%             )
       

    end
    
    % ==================================================================================================================================================
    %% PROPERTIES TIME
    % ==================================================================================================================================================
    
    properties (SetAccess = public, GetAccess = public)
        time           % internal time ref of the stored epochs
        desync         % receiver clock desync (difference between nominal time and the time of the observation)
        dt_ip          % clock error correction estimated during init positioning
        dt             % reference clock error of the receiver [n_epochs x num_obs_code]
    end
    % ==================================================================================================================================================
    %% PROPERTIES TROPO
    % ==================================================================================================================================================
    
    properties (SetAccess = public, GetAccess = public)
        apr_zhd  % zenital hydrostatic delay           double   [n_epoch x 1]
        ztd      % total zenital tropospheric delay    double   [n_epoch x 1]
        zwd      % zenital wet delay                   double   [n_epoch x 1]
        apr_zwd  % apriori zenital wet delay           double   [n_epoch x 1]
        pwv      % precipitable water vapour           double   [n_epoch x 1]
        
        tgn      % tropospheric gradient north         double   [n_epoch x n_sat]
        tge      % tropospheric gradient east          double   [n_epoch x n_sat]
    end
    
    % ==================================================================================================================================================
    %% PROPERTIES QUALITY INDEXES
    % ==================================================================================================================================================
    
    properties
        quality_info = struct('s0', [], 's0_ip', [], 'n_epochs', [], 'n_obs', [], 'n_out', [], 'n_sat', [], 'n_sat_max', [], 'fixing_ratio', [], 'C_pos_pos', []);
        a_fix
        s_rate
        n_sat_ep
    end
    
    % ==================================================================================================================================================
    %% PROPERTIES USEFUL HANDLES
    % ==================================================================================================================================================
    
    properties (SetAccess = protected, GetAccess = public)
        cc = Constellation_Collector('G');      % local cc
        w_bar                                  % handle to waitbar
        state                                  % local handle of state;
        log                                    % handle to log
        rf                                     % handle to reference farme
    end
    
    % ==================================================================================================================================================
    %% METHODS INIT - CLEAN - RESET - REM - IMPORT
    % ==================================================================================================================================================
    
    methods
        
        function initHandles(this)
            this.log = Core.getLogger();
            this.state = Core.getState();
            this.cc = this.state.getConstellationCollector;
            this.rf = Core.getReferenceFrame();
            this.w_bar = Go_Wait_Bar.getInstance();
        end
        
        function reset(this)
            this.time = GPS_Time();
            this.enu = [];
            this.lat = [];
            this.lon = [];
            
            this.h_ellips = [];
            this.h_ortho = [];
            
            this.quality_info = struct('s0', [], 's0_ip', [], 'n_epochs', [], 'n_obs', [], 'n_out', [], 'n_sat', [], 'n_sat_max', [], 'fixing_ratio', [], 'C_pos_pos', []);

            this.a_fix = [];
            this.s_rate = [];
            
            this.xyz = [];
            
            this.apr_zhd  = [];
            this.zwd  = [];
            this.apr_zwd  = [];
            this.ztd  = [];
            this.pwv  = [];
            
            this.tgn = [];
            this.tge = [];            
        end
    end
    % ==================================================================================================================================================
    %% METHODS GETTER - TIME
    % ==================================================================================================================================================
    
    methods
        function toStringPos(this)
            % Display on screen information about the receiver position
            % SYNTAX this.toStringPos();
            for r = 1 : numel(this)
                if ~this(r).isEmpty && ~isempty(this(r).xyz)
                    [lat, lon, h_ellips, h_ortho] = this(r).getMedianPosGeodetic_mr();
                    this(r).log.addMarkedMessage(sprintf('Receiver %s   %11.7f  %11.7f    %12.7f m (ellipsoidal) - %12.7f (orthometric)', this(r).parent.getMarkerName, lat, lon, h_ellips, h_ortho));
                end
            end
        end
        
        function is_empty = isEmpty(this)
            % Return if the object does not cantains any observation
            %
            % SYNTAX
            %   is_empty = this.isEmpty();
            is_empty =  this.time.length() == 0;
        end
        
        function is_empty = isEmpty_mr(this)
            % Return if the object does not cantains any observation
            %
            % SYNTAX
            %   is_empty = this.isEmpty();
            is_empty =  zeros(numel(this), 1);
            for r = 1 : numel(this)
                is_empty(r) =  this(r).isEmpty();
            end
        end
        
        function len = length(this)
            % Return the time span of the receiver
            %
            % SYNTAX
            %   len = this.length();
            len = this.getTime.length();
        end
        
        function dt = getDt(this)
            dt =  this.dt;
        end
        
        function dt_ip = getDtIP(this)
            dt_ip = this.dt_ip;
        end
        
        % time
        function time = getCentralTime(this)
            % return the central epoch time stored in the a receiver
            %
            % OUTPUT
            %   time     GPS_Time
            %
            % SYNTAX
            %   xyz = this.getCentralTime()
            time = this(1).time.getCentralTime();
        end
        
        function [rate] = getRate(this)
            % SYNTAX
            %   rate = this.getRate();
            rate = this.time.getRate;
        end
                
        function dt = getTotalDt(this)
            dt = this.getDt + this.getDtPrePro;
        end
        
        function coo = getPos(this)
            % return the positions computed for the receiver
            % as Coordinates object
            %
            % OUTPUT
            %   coo     coordinates object
            %
            % SYNTAX
            %   coo = this.getPos()
            
            if ~isempty(this.xyz)
                coo = Coordinates.fromXYZ(this.xyz);
            elseif ~isempty(this.parent.work.xyz)
                coo = Coordinates.fromXYZ(this.parent.work.xyz);
            else
                coo = Coordinates.fromXYZ([0 0 0]);
            end
            
        end
        
        function xyz = getPosXYZ(this)
            % return the positions computed for the receiver
            %
            % OUTPUT
            %   xyz     geocentric coordinates
            %
            % SYNTAX
            %   xyz = this.getPosXYZ()
            xyz = [];
            for r = 1 : numel(this)
                if ~isempty(this(r).xyz)
                    xyz = [xyz; this(r).xyz]; %#ok<AGROW>
                else
                    xyz = [xyz; this(r).parent.work.xyz]; %#ok<AGROW>
                end
            end
        end
        
        function [lat, lon, h_ellips, h_ortho] = getPosGeodetic(this)
            % Return the positions computed for the receiver
            %
            % OUTPUT
            %   lat      = latitude                      [rad]
            %   lon      = longitude                     [rad]
            %   h_ellips = ellipsoidal height            [m]
            %   lat_geoc = geocentric spherical latitude [rad]
            %   h_ortho  = orthometric height            [m]
            %
            % SYNTAX
            %   [lat, lon, h_ellips, h_ortho] = this.getGeodetic()
            
            coo = this.getPos();
            
            if nargout > 3
                [lat, lon, h_ellips, h_ortho] = coo.getGeodetic();
            elseif nargout > 2
                [lat, lon, h_ellips] = coo.getGeodetic();
            else
                [lat, lon] = coo.getGeodetic();
            end
        end
        
        function enu = getPosENU(this)
            % return the positions computed for the receiver
            %
            % OUTPUT
            %   enu     enu coordinates
            %
            % SYNTAX
            %   enu = this.getPosENU()
            enu = this.getPos().getENU();
        end
        
        function [utm, utm_zone] = getPosUTM(this)
            % return the positions computed for the receiver
            %
            % OUTPUT
            %   utm          utm coordinates
            %   utm_zone     utm zone
            %
            % SYNTAX
            %   [utm, utm_zone] = this.getPosUTM()
            [utm, utm_zone] =  this.getPos().getENU;
        end
        
        function enu = getBaselineENU(this, rec)
            % return the baseline computed for the receiver wrt another
            %
            % OUTPUT
            %   enu     enu coordinates
            %
            % SYNTAX
            %   enu = this.getPosENU()
            enu = this.getPosENU() - rec.getPosENU();
        end
        
        function xyz = getMedianPosXYZ(this)
            % return the computed median position of the receiver
            %
            % OUTPUT
            %   xyz     geocentric coordinates
            %
            % SYNTAX
            %   xyz = this.getMedianPosXYZ()
            
            xyz = this.getPosXYZ();
            xyz = median(xyz, 1, 'omitnan');
        end
        
        function enu = getMedianPosENU(this)
            % return the computed median position of the receiver
            %
            % OUTPUT
            %   enu     geocentric coordinates
            %
            % SYNTAX
            %   enu = this.getMedianPosENU()
            
            enu = this.getPosENU();
            enu = median(enu, 1, 'omitnan');
        end
        
        function [lat_d, lon_d, h_ellips, h_ortho] = getMedianPosGeodetic(this)
            % return the computed median position of the receiver
            %
            % OUTPUT
            %   lat         latitude  [deg]
            %   lon         longitude [deg]
            %   h_ellips    ellipsoidical heigth [m]
            %   h_ortho     orthometric heigth [m]
            %
            % SYNTAX
            %   [lat, lon, h_ellips, h_ortho] = this.getMedianPosGeodetic();
            for r = 1 : numel(this)
                xyz = this(r).getPosXYZ();
                xyz = median(xyz, 1);
                if ~isempty(this(r))
                    [lat_d(r), lon_d(r), h_ellips(r)] = cart2geod(xyz);
                    if nargout == 4
                        Core.initGeoid();
                        ondu = getOrthometricCorr(lat_d(r), lon_d(r), Core.getRefGeoid());
                        h_ortho(r) = h_ellips(r) - ondu;
                    end
                    lat_d(r) = lat_d(r) / pi * 180;
                    lon_d(r) = lon_d(r) / pi * 180;
                else
                    lat_d(r) = nan;
                    lon_d(r) = nan;
                    h_ellips(r) = nan;
                    h_ortho(r) = nan;
                end
            end
        end
        
        function ztd = getZtd(this)
            % get ztd
            %
            % SYNTAX
            %   ztd = this.getZtd()
            if max(this.getIdSync) > numel(this.ztd)
                ztd = nan(size(this.getIdSync));
            else
                ztd = this.ztd(this.getIdSync);
            end
        end
        
        function sztd = getSlantZTD(this, smooth_win_size, id_extract)
            % Get the "zenithalized" total delay
            % SYNTAX
            %   sztd = this.getSlantZTD(<flag_smooth_data = 0>)
            if nargin < 3
                id_extract = 1 : this.getTime.length;
            end
            
            if ~isempty(this(1).ztd)
                [mfh, mfw] = this.getSlantMF();
                sztd = bsxfun(@plus, (zero2nan(this.getSlantTD) - bsxfun(@times, mfh, this.getAprZhd)) ./ mfw, this.getAprZhd);
                sztd(sztd <= 0) = nan;
                sztd = sztd(id_extract, :);
                
                if nargin >= 2 && smooth_win_size > 0
                    t = this.getTime.getEpoch(id_extract).getRefTime;
                    for s = 1 : size(sztd,2)
                        id_ok = ~isnan(sztd(:, s));
                        if sum(id_ok) > 3
                            lim = getOutliers(id_ok);
                            lim = limMerge(lim, 2 * smooth_win_size / this.getRate);
                            
                            %lim = [lim(1) lim(end)];
                            for l = 1 : size(lim, 1)
                                if (lim(l, 2) - lim(l, 1) + 1) > 3
                                    id_ok = lim(l, 1) : lim(l, 2);
                                    ztd = this.getZtd();
                                    sztd(id_ok, s) = splinerMat(t(id_ok), sztd(id_ok, s) - zero2nan(ztd(id_ok)), smooth_win_size, 0.05) + zero2nan(ztd(id_ok));
                                end
                            end
                        end
                    end
                end
            else
                this(1).log.addWarning('ZTD and slants have not been computed');
            end
        end
        
        function apr_zhd = getAprZhd(this)
            % get a-priori ZHD
            %
            % SYNTAX
            %   zhd = this.getAprZhd()
            if max(this.getIdSync) > numel(this.apr_zhd)
                apr_zhd = nan(size(this.getIdSync));
            else
                apr_zhd = this.apr_zhd(this.getIdSync);
            end
        end
        
        function [n_sat, n_sat_ss] = getNSat(this)
            % get num sta per epoch
            %
            % OUTPUT
            %   n_sat       total number of sat in view
            %   n_sat_ss    struct(.G .E .R ...) number of sat per constellation
            %
            % SYNTAX
            %   [n_sat, n_sat_ss] = this.getNSat()
            if max(this.getIdSync) > numel(this.n_sat_ep)
                n_sat = nan(size(this.getIdSync));
                n_sat_ss.G = n_sat;
            else
                n_sat = this.n_sat_ep(this.getIdSync);
                if ~any(n_sat)
                    % retrieve the n_sat from residuals
                    n_sat = sum(this.sat.res(this.getIdSync,:) ~= 0, 2);
                    for sys_c = this.cc.sys_c
                        n_sat_ss.(sys_c) = sum(this.sat.res(this.getIdSync, this.cc.system == sys_c) ~= 0, 2);
                    end
                end
            end
        end
        
        function zwd = getZwd(this)
            % get zwd
            %
            % SYNTAX
            %   zwd = this.getZwd()
            if max(this.getIdSync) > numel(this.zwd)
                zwd = nan(size(this.getIdSync));
            else
                zwd = this.zwd(this.getIdSync);
                if isempty(zwd) || all(isnan(zero2nan(zwd)))
                    zwd = this.getAprZwd();
                end
            end
        end
        
        function pwv = getPwv(this)
            % get pwv
            %
            % SYNTAX
            %   pwv = this.getPwv()
            if max(this.getIdSync) > numel(this.pwv)
                pwv = nan(size(this.getIdSync));
            else
                pwv = this.pwv(this.getIdSync);
            end
        end
        
        function [gn ,ge, time] = getGradient(this)
            % SYNTAX
            % [gn ,ge, time] = getGradient(this)
            if isempty(this.tgn)
                gn = nan(length(this.getIdSync),1);
            else
                gn = this.tgn(this.getIdSync);
            end
            if isempty(this.tgn)
                ge = nan(length(this.getIdSync),1);
            else
                ge = this.tge(this.getIdSync);
            end
            time = this.time.getSubSet(this.getIdSync);
            
        end
        
        function [apr_zwd, time] = getAprZwd(this)
            % SYNTAX
            %  [apr_zwd, time] = this.getAprZwd()
            
            apr_zwd = this.apr_zwd(this.getIdSync);
            time = this.time.getEpoch(this.getIdSync);
        end
        
        function [az, el] = getAzEl(this)
            % Get the azimuth and elevation (on valid id_sync)
            %
            % SYNTAX
            %   [az, el] = this.getAzEl();
            az = this.getAz();
            el = this.getEl();
        end
        
        function [az] = getAz(this, go_id)
            % Get the azimuth (on valid id_sync)
            %
            % SYNTAX
            %   az = this.getAzEl();
            if isempty(this.sat.az)
                this.sat.az = nan(this.time.length, this.cc.getNumSat);
            end
            if nargin < 2
                go_id = 1 : size(this.sat.az, 2);
            end
            
            az = this.sat.az(this.getIdSync, go_id);
        end
        
        function [el] = getEl(this, go_id)
            % Get the azimuth and elevation (on valid id_sync)
            %
            % SYNTAX
            %   el = this.getEl();
            if isempty(this.sat.el)
                this.sat.el = nan(this.time.length, this.cc.getNumSat);
            end
            if nargin < 2
                go_id = 1 : size(this.sat.el, 2);
            end
            
            el = this.sat.el(this.getIdSync, go_id);
        end
        
        function res = getResidual(this)
            % get residual
            %
            % SYNTAX
            %   res = this.getResidual()
            res = this.sat.res(this.getIdSync(),:);
        end
        
        function out_prefix = getOutPrefix(this)
            % Get the name for exporting output (valid for dayly output)
            %   - marker name 4ch (from rinex file name)
            %   - 4 char year
            %   - 3 char doy
            %
            % SYNTAX
            time = this.time.getCopy;
            [year, doy] = time.getCentralTime.getDOY();
            out_prefix = sprintf('%s_%04d_%03d_', this.getMarkerName4Ch, year, doy);
        end
        
        function [sys_c, prn] = getSysPrn(this, go_id)
            % Return sys_c and prn for a given go_id
            %
            % SYNTAX
            %    [sys_c, prn] = this.getSysPrn(go_id)
            [sys_c, prn] = this.cc.getSysPrn(go_id);
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
    end
    
    
    % ==================================================================================================================================================
    %% METHODS IMPORT / EXPORT
    % ==================================================================================================================================================
    
    methods
        function exportTropoSINEX(this, param_to_export)
            % exprot tropspheric product in a sinex file
            %
            % SYNTAX:
            %    exportTropoSinex(this, <param_to_export>)
            if nargin < 2
                param_to_export = [ 1 1 1 0 0 0 0 0];
            end
            for r = 1 : numel(this)
                if min(this(r).quality_info.s0) < 0.10 % If there is at least one good session export the data
                    try
                        rec = this(r);
                        if ~isempty(rec.getZtd)
                            [year, doy] = rec.time.first.getDOY();
                            yy = num2str(year);
                            yy = yy(3:4);
                            sess_str = '0'; %think how to get the right one from sss_id_list
                            fname = sprintf('%s',[rec.state.getOutDir() filesep rec.parent.marker_name sprintf('%03d', doy) sess_str '.' yy 'zpd']);
                            snx_wrt = SINEX_Writer(fname);
                            snx_wrt.writeTroSinexHeader( rec.time.first, rec.time.getSubSet(rec.time.length), rec.parent.marker_name)
                            snx_wrt.writeFileReference()
                            snx_wrt.writeAcknoledgments()
                            smpl_tropo = median(diff(rec.getIdSync)) * rec.time.getRate;
                            snx_wrt.writeTropoDescription(rec.state.cut_off, rec.time.getRate, smpl_tropo, snx_wrt.SINEX_MAPPING_FLAGS{this.state.mapping_function}, SINEX_Writer.SUPPORTED_PARAMETERS(param_to_export>0), false(length(param_to_export),1))
                            snx_wrt.writeSTACoo( rec.parent.marker_name, rec.xyz(1,1), rec.xyz(1,2), rec.xyz(1,3), 'UNDEF', 'GRD'); % The reference frame depends on the used orbit so it is generraly labled undefined a more intelligent strategy could be implemented
                            snx_wrt.writeTropoSolutionSt()
                            data = [];
                            if param_to_export(1)
                                data = [data rec.ztd(rec.getIdSync,:)*1e3 ];
                            end
                            if param_to_export(2)
                                data = [data rec.tgn(rec.getIdSync,:)*1e3 ];
                            end
                            if param_to_export(3)
                                data = [data rec.tge(rec.getIdSync,:)*1e3];
                            end
                            if param_to_export(4)
                                data = [data rec.getZwd*1e3];
                            end
                            if param_to_export(5)
                                data = [data rec.getPwv*1e3];
                            end
                            [P,T,H] = this.getPTH();
                            if param_to_export(6)
                                data = [data P];
                            end
                            if param_to_export(7)
                                data = [data T];
                            end
                            if param_to_export(8)
                                data = [data H];
                            end
                            snx_wrt.writeTropoSolutionStation(rec.parent.marker_name, rec.time.getEpoch(rec.getIdSync), data, [], param_to_export)
                            snx_wrt.writeTropoSolutionEnd()
                            snx_wrt.writeTroSinexEnd();
                            snx_wrt.close()
                            rec(1).log.addStatusOk(sprintf('Tropo saved into: %s', fname));
                        end
                    catch ex
                        rec(1).log.addError(sprintf('saving Tropo in sinex format failed: %s', ex.message));
                    end
                else
                    this(1).log.addWarning(sprintf('s02(%f m) too bad, station skipped', max(this(r).quality_info.s0)));
                end
            end
        end
        
        function exportTropoMat(this)
            % Export the troposphere into a MATLAB data format file
            % The data exported are:
            %  - lat
            %  - lon
            %  - h_ellips
            %  - h_ortho
            %  - ztd
            %  - time_utc in matlab format
            %
            % SYNTAX
            %   this.exportTropoMat
            
            for r = 1 : numel(this)
                if max(this(r).quality_info.s0) < 0.10
                    try
                        this(r).updateCoordinates;
                        time = this(r).getTime();
                        [year, doy] = this(r).getCentralTime.getDOY();
                        time.toUtc();
                        
                        lat = this(r).lat; %#ok<NASGU>
                        lon = this(r).lon; %#ok<NASGU>
                        h_ellips = this(r).h_ellips; %#ok<NASGU>
                        h_ortho = this(r).h_ortho; %#ok<NASGU>
                        ztd = this(r).getZtd(); %#ok<NASGU>
                        utc_time = time.getMatlabTime; %#ok<NASGU>
                        
                        fname = sprintf('%s',[this(r).state.getOutDir() filesep this(r).parent.marker_name sprintf('%04d%03d',year, doy) '.mat']);
                        save(fname, 'lat', 'lon', 'h_ellips', 'h_ortho', 'ztd', 'utc_time','-v6');
                        
                        this(1).log.addStatusOk(sprintf('Tropo saved into: %s', fname));
                    catch ex
                        this(1).log.addError(sprintf('saving Tropo in matlab format failed: %s', ex.message));
                    end
                else
                    this(1).log.addWarning(sprintf('s02(%f m) too bad, station skipped', max(this(r).quality_info.s0)));
                end
            end
        end
        
        function txt = exportWrfLittleR(this, save_on_disk)
            % export WRF-compatible file (LITTLE_R)
            if nargin == 1
                save_on_disk = true;
            end
            if save_on_disk
                [year, doy] = this.time.first.getDOY();
                yy = num2str(year);
                yy = yy(3:4);
                sess_str = '0'; % think how to get the right one from sss_id_list
                fname = sprintf([this.state.getOutDir() '/' this.parent.marker_name '%03d' sess_str '.' yy 'GPSZTD'], doy);
                fid = fopen(fname,'w');
            end
            this.updateCoordinates();
            meas_time = this.time.getSubSet(this.id_sync);
            meas_time.toUnixTime();
            txt = '';
            for i = 1 : length(this.id_sync)
                txt = sprintf(['%20.5f%20.5f%40s%40s%40s%40s%20.5f         0         0         0         0         0         F         F         F         0    ' ...
                    '     0%20s-888888.00000-888888-888888.00000-888888-888888.00000-888888-888888.00000-888888-888888.00000-888888-888888.00000-888888' ...
                    '-888888.00000-888888-888888.00000-888888-888888.00000-888888-888888.00000-888888-888888.00000-888888-888888.00000-888888-'...
                    '888888.00000-888888%13.5f      0-888888.00000-888888-888888.00000      0%13.5f      0-888888.00000      0-888888.00000-888888' ...
                    '-888888.00000-888888-888888.00000-888888-888888.00000-888888-888888.00000-888888-888888.00000-888888-888888.00000-888888', ...
                    '-777777.00000      0-777777.00000      0-888888.00000      0-888888.00000      0-888888.00000      0-888888.00000      0' ...
                    '-888888.00000      0-888888.00000      0-888888.00000      0-888888.00000      0\n'],...
                    this.lat, ...
                    this.lon, ...
                    this.parent.marker_name, ...
                    this.parent.marker_type, ...
                    'FM-114 GPSZTD', ...
                    'goGPS software', ...
                    this.h_ortho, ...
                    this.time.toString('yyyymmddHHMMSS'), ...
                    this.ztd(this.id_sync(i))*100, ...
                    this.h_ortho);
            end
            if save_on_disk
                fprintf(fid,'%s', tmp);
                fclose(fid);
            end
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
            if size(this.xyz, 1) > 1
                this.showPositionENU();
                this.showPositionXYZ();
            end
            %this.showMap();
            this.showZtd();
            this.showZtdSlant();
            this.showZtdSlantRes_p();
            this.showResSky_p();
            this.showResSky_c();
            this.showOutliersAndCycleSlip();
            this.showOutliersAndCycleSlip_p();
            dockAllFigures();
        end
        
        function showPositionENU(this, one_plot)
            % Plot East North Up coordinates of the receiver (as estimated by initDynamicPositioning
            % SYNTAX this.plotPositionENU();
            if nargin == 1
                one_plot = false;
            end
            
            for r = 1 : numel(this)
                rec = this(r);
                if ~isempty(rec)
                    xyz = rec.getPosXYZ();
                    if size(xyz, 1) > 1
                        rec(1).log.addMessage('Plotting positions');
                        
                        f = figure; f.Name = sprintf('%03d: PosENU', f.Number); f.NumberTitle = 'off';
                        color_order = handle(gca).ColorOrder;
                        
                        xyz = rec.getPosXYZ();
                        xyz0 = rec.getMedianPosXYZ();
                        
                        t = rec.getPositionTime().getMatlabTime();
                        
                        [enu0(:,1), enu0(:,2), enu0(:,3)] = cart2plan(xyz0(:,1), xyz0(:,2), xyz0(:,3));
                        [enu(:,1), enu(:,2), enu(:,3)] = cart2plan(zero2nan(xyz(:,1)), zero2nan(xyz(:,2)), zero2nan(xyz(:,3)));
                        
                        if ~one_plot, subplot(3,1,1); end
                        plot(t, (1e2 * (enu(:,1) - enu0(1))), '.-', 'MarkerSize', 15, 'LineWidth', 2, 'Color', color_order(1,:)); hold on;
                        ax(3) = gca();
                        if (t(end) > t(1))
                            xlim([t(1) t(end)]);
                        end
                        setTimeTicks(4,'dd/mm/yyyy HH:MMPM'); h = ylabel('East [cm]'); h.FontWeight = 'bold';
                        grid on;
                        h = title(sprintf('Receiver %s \n std %.2f [cm]', rec(1).parent.marker_name,sqrt(var(enu(:,1)*1e2))),'interpreter', 'none'); h.FontWeight = 'bold'; %h.Units = 'pixels'; h.Position(2) = h.Position(2) + 8; h.Units = 'data';
                        if ~one_plot, subplot(3,1,2); end
                        plot(t, (1e2 * (enu(:,2) - enu0(2))), '.-', 'MarkerSize', 15, 'LineWidth', 2, 'Color', color_order(2,:));
                        ax(2) = gca();
                        if (t(end) > t(1))
                            xlim([t(1) t(end)]);
                        end
                        setTimeTicks(4,'dd/mm/yyyy HH:MMPM'); h = ylabel('North [cm]'); h.FontWeight = 'bold';
                        h = title(sprintf('std %.2f [cm]',sqrt(var(enu(:,2)*1e2))),'interpreter', 'none'); h.FontWeight = 'bold';
                        grid on;
                        if ~one_plot, subplot(3,1,3); end
                        plot(t, (1e2 * (enu(:,3) - enu0(3))), '.-', 'MarkerSize', 15, 'LineWidth', 2, 'Color', color_order(3,:));
                        ax(1) = gca();
                        if (t(end) > t(1))
                            xlim([t(1) t(end)]);
                        end
                        setTimeTicks(4,'dd/mm/yyyy HH:MMPM'); h = ylabel('Up [cm]'); h.FontWeight = 'bold';
                        h = title(sprintf('std %.2f [cm]',sqrt(var(enu(:,3)*1e2))),'interpreter', 'none'); h.FontWeight = 'bold';
                        grid on;
                        if one_plot
                            h = ylabel('ENU [cm]'); h.FontWeight = 'bold';
                        else
                            linkaxes(ax, 'x');
                        end
                        grid on;
                        
                    else
                        rec(1).log.addMessage('Plotting a single point static position is not yet supported');
                    end
                end
            end
        end
        
        function showPositionXYZ(this, one_plot)
            % Plot X Y Z coordinates of the receiver (as estimated by initDynamicPositioning
            % SYNTAX this.plotPositionXYZ();
            if nargin == 1
                one_plot = false;
            end
            
            for r = 1 : numel(this)
                rec = this(r);
                if ~isempty(rec)
                    xyz = rec.getPosXYZ();
                    if size(xyz, 1) > 1
                        rec(1).log.addMessage('Plotting XYZ positions');
                        
                        f = figure; f.Name = sprintf('%03d: PosXYZ', f.Number); f.NumberTitle = 'off';
                        color_order = handle(gca).ColorOrder;
                        
                        xyz = rec(:).getPosXYZ();
                        xyz0 = rec(:).getMedianPosXYZ();
                        
                        t = rec.getPositionTime().getMatlabTime;
                        
                        x = 1e2 * bsxfun(@minus, zero2nan(xyz(:,1)), xyz0(1));
                        y = 1e2 * bsxfun(@minus, zero2nan(xyz(:,2)), xyz0(2));
                        z = 1e2 * bsxfun(@minus, zero2nan(xyz(:,3)), xyz0(3));
                        
                        if ~one_plot, subplot(3,1,1); end
                        plot(t, x, '.-', 'MarkerSize', 15, 'LineWidth', 2, 'Color', color_order(1,:));  hold on;
                        ax(3) = gca(); xlim([t(1) t(end)]); setTimeTicks(4,'dd/mm/yyyy HH:MMPM'); h = ylabel('X [cm]'); h.FontWeight = 'bold';
                        grid on;
                        h = title(sprintf('Receiver %s', rec(1).parent.marker_name),'interpreter', 'none'); h.FontWeight = 'bold'; %h.Units = 'pixels'; h.Position(2) = h.Position(2) + 8; h.Units = 'data';
                        if ~one_plot, subplot(3,1,2); end
                        plot(t, y, '.-', 'MarkerSize', 15, 'LineWidth', 2, 'Color', color_order(2,:));
                        ax(2) = gca(); xlim([t(1) t(end)]); setTimeTicks(4,'dd/mm/yyyy HH:MMPM'); h = ylabel('Y [cm]'); h.FontWeight = 'bold';
                        grid on;
                        if ~one_plot, subplot(3,1,3); end
                        plot(t, z, '.-', 'MarkerSize', 15, 'LineWidth', 2, 'Color', color_order(3,:));
                        ax(1) = gca(); xlim([t(1) t(end)]); setTimeTicks(4,'dd/mm/yyyy HH:MMPM'); h = ylabel('Z [cm]'); h.FontWeight = 'bold';
                        grid on;
                        if one_plot
                            h = ylabel('XYZ [m]'); h.FontWeight = 'bold';
                        end
                        linkaxes(ax, 'x');
                    else
                        rec.log.addMessage('Plotting a single point static position is not yet supported');
                    end
                end
            end
        end
        
        function showPositionSigmas(this, one_plot)
            % Show Sigmas of the solutions
            %
            % SYNTAX
            %   this.showPositionSigmas();
            
            if nargin == 1
                one_plot = false;
            end
            
            rec = this;
            if ~isempty(rec)
                xyz = rec(1).getPosXYZ();
                if size(xyz, 1) > 1
                    rec(1).log.addMessage('Plotting ENU sigmas');
                    
                    f = figure; f.Name = sprintf('%03d: sigma processing', f.Number); f.NumberTitle = 'off';
                    color_order = handle(gca).ColorOrder;
                    
                    s0 = rec.quality_info.s0;
                    s0_ip = rec.quality_info.s0_ip;
                    
                    t = rec.getPositionTime().getMatlabTime;
                    
                    if ~one_plot, subplot(2,1,2); end
                    plot(t, s0 * 1e2, '.-', 'MarkerSize', 15, 'LineWidth', 2, 'Color', color_order(1,:));  hold on;
                    ax(2) = gca(); xlim([t(1) t(end)]); setTimeTicks(4,'dd/mm/yyyy HH:MMPM'); h = ylabel('s0 [cm]'); h.FontWeight = 'bold';
                    grid on;
                    if ~one_plot, subplot(2,1,1); end
                    plot(t, s0_ip * 1e2, '.-', 'MarkerSize', 15, 'LineWidth', 2, 'Color', color_order(2,:));
                    ax(1) = gca(); xlim([t(1) t(end)]); setTimeTicks(4,'dd/mm/yyyy HH:MMPM'); h = ylabel('s0 ip [cm]'); h.FontWeight = 'bold';
                    h = title(sprintf('Receiver %s', rec(1).parent.marker_name),'interpreter', 'none'); h.FontWeight = 'bold'; %h.Units = 'pixels'; h.Position(2) = h.Position(2) + 8; h.Units = 'data';
                    grid on;
                    if one_plot
                        h = ylabel('Sigmas of the processing [cm]'); h.FontWeight = 'bold';
                    end
                    linkaxes(ax, 'x');
                else
                    rec.log.addMessage('Plotting a single point static position is not yet supported');
                end
            end
        end
        
        function showMap(this, new_fig)
            if nargin < 2
                new_fig = true;
            end
            if new_fig
                f = Mapper();
                if isa(f,'Mapper')
                    f = f.fig;
                end
            else
                f = gcf;
                hold on;
            end
            maximizeFig(f);
            [lat, lon] = this.getMedianPosGeodetic();
            
            plot(lon(:), lat(:),'.w','MarkerSize', 30);
            hold on;
            plot(lon(:), lat(:),'.k','MarkerSize', 10);
            plot(lon(:), lat(:),'ko','MarkerSize', 10, 'LineWidth', 2);
            
            if numel(this) == 1
                lon_lim = minMax(lon);
                lat_lim = minMax(lat);
                lon_lim(1) = lon_lim(1) - 0.05;
                lon_lim(2) = lon_lim(2) + 0.05;
                lat_lim(1) = lat_lim(1) - 0.05;
                lat_lim(2) = lat_lim(2) + 0.05;
            else
                lon_lim = xlim();
                lon_lim(1) = lon_lim(1) - diff(lon_lim)/3;
                lon_lim(2) = lon_lim(2) + diff(lon_lim)/3;
                lat_lim = ylim();
                lat_lim(1) = lat_lim(1) - diff(lat_lim)/3;
                lat_lim(2) = lat_lim(2) + diff(lat_lim)/3;
            end
            
            xlim(lon_lim);
            ylim(lat_lim);
            
            for r = 1 : numel(this)
                name = upper(this(r).parent.getMarkerName4Ch());
                t = text(lon(r), lat(r), [' ' name ' '], ...
                    'FontWeight', 'bold', 'FontSize', 10, 'Color', [0 0 0], ...
                    'BackgroundColor', [1 1 1], 'EdgeColor', [0.3 0.3 0.3], ...
                    'Margin', 2, 'LineWidth', 2, ...
                    'HorizontalAlignment','left');
                t.Units = 'pixels';
                t.Position(1) = t.Position(1) + 10 + 10 * double(numel(this) == 1);
                t.Units = 'data';
            end
            
            plot_google_map('alpha', 0.95, 'MapType', 'satellite');
            title('Receiver position');
            xlabel('Longitude [deg]');
            ylabel('Latitude [deg]');
        end
        
        
        function showResSky_p(this, sys_c_list)
            % Plot residuals of the solution on polar scatter
            % SYNTAX this.plotResSkyPolar(sys_c)
            
            if isempty(this.sat.res)
                this.log.addWarning('Residuals have not been computed');
            else
                if nargin == 1
                    sys_c_list = unique(this.cc.system);
                end
                
                for sys_c = sys_c_list
                    s = this.cc.getGoIds(sys_c);%this.go_id(this.system == sys_c);
                    res = abs(this.sat.res(:, s));
                    
                    f = figure; f.Name = sprintf('%03d: Res P %s', f.Number, this.cc.getSysName(sys_c)); f.NumberTitle = 'off';
                    id_ok = (res~=0);
                    az = this.sat.az(:, s);
                    el = this.sat.el(:, s);
                    polarScatter(serialize(az(id_ok))/180*pi,serialize(90-el(id_ok))/180*pi, 45, serialize(res(id_ok)), 'filled');
                    caxis([min(abs(this.sat.res(:))) min(20, min(6*std(zero2nan(this.sat.res(:)),'omitnan'), max(abs(zero2nan(this.sat.res(:))))))]);
                    colormap(flipud(hot)); f.Color = [.95 .95 .95]; colorbar();
                    h = title(sprintf('Satellites residuals [m] - receiver %s - %s', this.parent.marker_name, this.cc.getSysExtName(sys_c)),'interpreter', 'none');  h.FontWeight = 'bold'; h.Units = 'pixels'; h.Position(2) = h.Position(2) + 20; h.Units = 'data';
                end
            end
        end
        
        function showResSky_c(this, sys_c_list)
            % Plot residuals of the solution on cartesian axes
            % SYNTAX this.plotResSkyCart()
            if isempty(this.sat.res)
                this.log.addWarning('Residuals have not been computed');
            else
                if nargin == 1
                    sys_c_list = unique(this.cc.system);
                end
                
                for sys_c = sys_c_list
                    s  = this.cc.getGoIds(sys_c);%unique(this.go_id(this.system == sys_c));
                    res = abs(this.sat.res(:, s));
                    
                    f = figure; f.Name = sprintf('%03d: Res C %s', f.Number, this.cc.getSysName(sys_c)); f.NumberTitle = 'off';
                    %this.updateAzimuthElevation()
                    id_ok = (res~=0);
                    az = this.sat.az(:, s);
                    el = this.sat.el(:, s);
                    scatter(serialize(az(id_ok)),serialize(el(id_ok)), 45, serialize(res(id_ok)), 'filled');
                    caxis([min(abs(this.sat.res(:))) min(20, min(6*std(zero2nan(this.sat.res(:)),'omitnan'), max(abs(zero2nan(this.sat.res(:))))))]);
                    colormap(flipud(hot)); f.Color = [.95 .95 .95]; colorbar(); ax = gca; ax.Color = 'none';
                    h = title(sprintf('Satellites residuals [m] - receiver %s - %s', this.parent.marker_name, this.cc.getSysExtName(sys_c)),'interpreter', 'none');  h.FontWeight = 'bold'; h.Units = 'pixels'; h.Position(2) = h.Position(2) + 20; h.Units = 'data';
                    hl = xlabel('Azimuth [deg]'); hl.FontWeight = 'bold';
                    hl = ylabel('Elevation [deg]'); hl.FontWeight = 'bold';
                end
            end
        end
        
        function showRes(sta_list)            
            % In a future I could use multiple tabs for each constellation
            for r = numel(sta_list)
                work = sta_list(r);
                if ~work.isEmpty
                    
                    win = figure('Visible', 'on', ...
                        'NumberTitle', 'off', ...
                        'units', 'normalized', ...
                        'outerposition', [0 0 1 1]); % create maximized figure
                    win.Name = sprintf('%03d - %s residuals', win.Number, work.parent.getMarkerName4Ch);
                    v_main = uix.VBoxFlex('Parent', win, ...
                        'Spacing', 5);
                    
                    % Axe with all the satellites
                    overview_box = uix.VBoxFlex('Parent', v_main, ...
                        'BackgroundColor', Core_UI.LIGHT_GRAY_BG);
                    
                    ax_all = axes('Parent', overview_box, 'Units', 'normalized');
                    
                    % Single sat axes
                    n_sat = work.getMaxSat;
                    
                    sat_box = uix.VBoxFlex('Parent', v_main, ...
                        'Padding', 5, ...
                        'BackgroundColor', Core_UI.LIGHT_GRAY_BG);
                    
                    v_main.Heights = [-2 -5];
                    
                    scroller = uix.ScrollingPanel('Parent', sat_box);
                    sat_grid = uix.Grid('Parent', scroller, ...
                        'BackgroundColor', Core_UI.LIGHT_GRAY_BG);
                    scroller.Heights = 120 * ceil(n_sat / 4);
                    for s = 1 : n_sat
                        single_sat(s) = uix.VBox('Parent', sat_grid, ...
                            'BackgroundColor', Core_UI.LIGHT_GRAY_BG);
                        uicontrol('Parent', single_sat(s), ...
                            'Style', 'Text', ...
                            'String', sprintf('Satellite %s', work.cc.getSatName(s)), ...
                            'ForegroundColor', Core_UI.BLACK, ...
                            'HorizontalAlignment', 'center', ...
                            'FontSize', Core_UI.getFontSize(7), ...
                            'FontWeight', 'Bold', ...
                            'BackgroundColor', Core_UI.LIGHT_GRAY_BG);
                        ax_sat(s) = axes('Parent', single_sat(s));
                    end
                    sat_grid.Heights = -ones(1, ceil(n_sat / 4));
                    for s = 1 : n_sat
                        single_sat(s).Heights = [18, -1];
                        drawnow
                    end
                    
                    %% fill the axes
                    win.Visible = 'on';
                    colors = Core_UI.getColor(1 : n_sat, n_sat);
                    ax_all.ColorOrder = colors; hold(ax_all, 'on');
                    plot(ax_all, work.time.getMatlabTime, zero2nan(work.sat.res)*1e3, '.-');
                    setTimeTicks(ax_all, 3,'dd/mm/yyyy HH:MMPM');
                    drawnow; ylabel('residuals [mm]'); grid on;
                    
                    id_ok = false(n_sat, 1);
                    for s = 1 : n_sat
                        res = zero2nan(work.sat.res(:,s))*1e3;
                        id_ok(s) = any(res);
                        if id_ok(s)
                            plot(ax_sat(s), work.time.getMatlabTime, res, '-', 'LineWidth', 2, 'Color', colors(s, :));
                            grid on; ax_sat(s).YMinorGrid = 'on'; ax_sat(s).XMinorGrid = 'on';
                            %setTimeTicks(ax_sat(s), 2,'HH:MMPM');
                        else
                            single_sat(s).Visible = 'off';
                        end
                    end
                    linkaxes([ ax_all,ax_sat(id_ok)]);
                    drawnow
                end
            end
            
        end
        
        function showAniZtdSlant(this, time_start, time_stop, show_map, write_video)
            sztd = this.getSlantZTD(this.parent.slant_filter_win);
            if isempty(this.ztd) || ~any(sztd(:))
                this.log.addWarning('ZTD and slants have not been computed');
            else
                f = figure; f.Name = sprintf('%03d: AniZtd', f.Number); f.NumberTitle = 'off';                
                
                if nargin >= 3
                    if isa(time_start, 'GPS_Time')
                        time_start = find(this.time.getMatlabTime >= time_start.first.getMatlabTime(), 1, 'first');
                        time_stop = find(this.time.getMatlabTime <= time_stop.last.getMatlabTime(), 1, 'last');
                    end
                    time_start = max(1, time_start);
                    time_stop = min(size(sztd,1), time_stop);
                else
                    time_start = 1;
                    time_stop = size(sztd,1);
                end
                
                id_sync = serialize(this(1).getIdSync);
                if isempty(id_sync)
                    id_sync(:, 1) = (1 : this.time.length())';
                end
                id_ok = id_sync(id_sync(:) > time_start & id_sync(:) < time_stop);
                t = this.time.getEpoch(id_ok).getMatlabTime;
                sztd = sztd(id_ok, :);
                
                if nargin < 4
                    show_map = true;
                end
                if nargin < 5
                    write_video = false;
                else
                    if write_video
                        vidObj = VideoWriter('./out.avi');
                        vidObj.FrameRate = 30;
                        vidObj.Quality = 100;
                        open(vidObj);
                    end
                end
                yl = (median(median(sztd, 'omitnan'), 'omitnan') + ([-6 6]) .* median(std(sztd, 'omitnan'), 'omitnan')) * 1e2;
                
                subplot(3,1,3);
                plot(t, sztd * 1e2,'.'); hold on;
                plot(t, this.ztd(id_ok) * 1e2,'k', 'LineWidth', 4);
                ylim(yl);
                hl = line('XData', t(1) * [1 1],'YData', yl, 'LineWidth', 2);
                xlim([t(1) t(end)]);
                setTimeTicks(4,'dd/mm/yy HH:MM');
                h = ylabel('ZTD [cm]'); h.FontWeight = 'bold';
                grid on;
                
                % polar plot "true" Limits
                e_grid = [-1 : 0.2 : 1];
                n_grid = [-1 : 0.2 : 1];
                [ep, np] = meshgrid(e_grid, n_grid);
                fun = @(dist) exp(-((dist*1e5)/3e4).^2);
                
                ax_sky = subplot(3,1,1:2); i = time_start;
                az = (mod(this.sat.az(id_ok(i),:) + 180, 360) -180) ./ 180 * pi; az(isnan(az) | isnan(sztd(i,:))) = 1e10;
                el = (90 - this.sat.el(id_ok(i),:)) ./ 180 * pi; el(isnan(el) | isnan(sztd(i,:))) = 1e10;
                
                if show_map
                    td = nan(size(ep));
                    hm = imagesc(e_grid, n_grid, reshape(td(:), numel(n_grid), numel(e_grid))); hold on;
                    hm.AlphaData = 0.5;
                    ax_sky.YDir = 'normal';
                end
                hs = polarScatter(az, el, 250, sztd(i,:) * 1e2, 'filled');
                xlim([-1 1]); ylim([-1 1]);
                caxis(yl); colormap(jet(1024)); colorbar;
                
                subplot(3,1,3);
                for i = 2 : 2 : numel(id_ok)
                    % Move scattered points
                    az = (mod(this.sat.az(id_sync(i, 1),:) + 180, 360) -180) ./ 180 * pi; az(isnan(az) | isnan(sztd(i,:))) = 1e10;
                    el = (90 - this.sat.el(id_sync(i, 1),:)) ./ 180 * pi; el(isnan(el) | isnan(sztd(i,:))) = 1e10;
                    decl_n = el/(pi/2);
                    x = sin(az) .* decl_n;
                    y = cos(az) .* decl_n;
                    
                    id_ok = not(isnan(zero2nan(sztd(i,:))));
                    if show_map
                        if any(id_ok(:))
                            td = funInterp2(ep(:), np(:), x(1, id_ok)', y(1, id_ok)', sztd(i, id_ok)' * 1e2, fun);
                            hm.CData = reshape(td(:), numel(n_grid), numel(e_grid));
                        end
                    end
                    
                    hs.XData = x;
                    hs.YData = y;
                    hs.CData = sztd(i,:) * 1e2;
                    
                    % Move time line
                    hl.XData = t(i) * [1 1];
                    drawnow;
                    
                    if write_video
                        currFrame = export_fig(fig_h, '-nocrop', '-a1');
                        writeVideo(vidObj,currFrame);
                    end
                end
                if write_video
                    close(vidObj);
                end
            end
        end
        
        function showAniZwdSlant(this, time_start, time_stop, show_map)
            if isempty(this.zwd) || ~any(this.sat.slant_td(:))
                this.log.addWarning('ZWD and slants have not been computed');
            else
                f = figure; f.Name = sprintf('%03d: AniZwd', f.Number); f.NumberTitle = 'off';
                szwd = this.getSlantZWD(this.parent.slant_filter_win);
                
                if nargin >= 3
                    if isa(time_start, 'GPS_Time')
                        time_start = find(this.time.getMatlabTime >= time_start.first.getMatlabTime(), 1, 'first');
                        time_stop = find(this.time.getMatlabTime <= time_stop.last.getMatlabTime(), 1, 'last');
                    end
                    time_start = max(1, time_start);
                    time_stop = min(size(szwd,1), time_stop);
                else
                    time_start = 1;
                    time_stop = size(szwd,1);
                end
                
                if isempty(this.id_sync(:))
                    this.id_sync = (1 : this.time.length())';
                end
                id_ok = this.id_sync(this.id_sync > time_start & this.id_sync < time_stop, 1);
                
                t = this.time.getEpoch(id_ok).getMatlabTime;
                szwd = szwd(id_ok, :);
                
                if nargin < 4
                    show_map = true;
                end
                yl = (median(median(szwd, 'omitnan'), 'omitnan') + ([-6 6]) .* median(std(szwd, 'omitnan'), 'omitnan')) * 1e2;
                
                subplot(3,1,3);
                plot(t, szwd * 1e2,'.'); hold on;
                plot(t, this.zwd(id_ok) * 1e2,'k', 'LineWidth', 4);
                ylim(yl);
                hl = line('XData', t(1) * [1 1],'YData', yl, 'LineWidth', 2);
                xlim([t(1) t(end)]);
                setTimeTicks(4,'dd/mm/yyyy HH:MMPM');
                h = ylabel('ZWD [cm]'); h.FontWeight = 'bold';
                grid on;
                
                % polar plot "true" Limits
                e_grid = [-1 : 0.1 : 1];
                n_grid = [-1 : 0.1 : 1];
                [ep, np] = meshgrid(e_grid, n_grid);
                fun = @(dist) exp(-((dist*1e5)/3e4).^2);
                
                ax_sky = subplot(3,1,1:2); i = time_start;
                az = (mod(this.sat.az(id_ok(i),:) + 180, 360) -180) ./ 180 * pi; az(isnan(az) | isnan(szwd(i,:))) = 1e10;
                el = (90 - this.sat.el(id_ok(i),:)) ./ 180 * pi; el(isnan(el) | isnan(szwd(i,:))) = 1e10;
                
                if show_map
                    td = nan(size(ep));
                    hm = imagesc(e_grid, n_grid, reshape(td(:), numel(n_grid), numel(e_grid))); hold on;
                    hm.AlphaData = 0.5;
                    ax_sky.YDir = 'normal';
                end
                hs = polarScatter(az, el, 250, szwd(i,:) * 1e2, 'filled');
                caxis(yl); colormap(jet(1024)); colorbar;
                
                subplot(3,1,3);
                for i = 2 : numel(id_ok)
                    % Move scattered points
                    az = (mod(this.sat.az(this.id_sync(i, 1),:) + 180, 360) -180) ./ 180 * pi; az(isnan(az) | isnan(szwd(i,:))) = 1e10;
                    el = (90 - this.sat.el(this.id_sync(i, 1),:)) ./ 180 * pi; el(isnan(el) | isnan(szwd(i,:))) = 1e10;
                    decl_n = el/(pi/2);
                    x = sin(az) .* decl_n;
                    y = cos(az) .* decl_n;
                    
                    id_ok = not(isnan(zero2nan(szwd(i,:))));
                    if show_map
                        if any(id_ok(:))
                            td = funInterp2(ep(:), np(:), x(1, id_ok)', y(1, id_ok)', szwd(i, id_ok)' * 1e2, fun);
                            hm.CData = reshape(td(:), numel(n_grid), numel(e_grid));
                        end
                    end
                    
                    hs.XData = x;
                    hs.YData = y;
                    hs.CData = szwd(i,:) * 1e2;
                    
                    % Move time line
                    hl.XData = t(i) * [1 1];
                    drawnow;
                end
            end
        end
        
        function showZtdSlant(this, time_start, time_stop)
            %if isempty(this(1).ztd) || ~any(this(1).sat.slant_td(:))
            %    this(1).log.addWarning('ZTD and/or slants have not been computed');
            %else
            rec = this;
            if isempty(rec)
                this(1).log.addWarning('ZTD and/or slants have not been computed');
            else
                f = figure; f.Name = sprintf('%03d: Ztd Slant %s', f.Number, rec(1).cc.sys_c); f.NumberTitle = 'off';
                t = rec(:).getTime.getMatlabTime;
                
                sztd = rec(:).getSlantZTD(rec(1).parent.slant_filter_win);
                if nargin >= 3
                    if isa(time_start, 'GPS_Time')
                        time_start = find(t >= time_start.first.getMatlabTime(), 1, 'first');
                        time_stop = find(t <= time_stop.last.getMatlabTime(), 1, 'last');
                    end
                    time_start = max(1, time_start);
                    time_stop = min(size(sztd,1), time_stop);
                else
                    time_start = 1;
                    time_stop = size(sztd,1);
                end
                
                if nargin < 4
                    win_size = (t(time_stop) - t(time_start)) * 86400;
                end
                
                %yl = (median(median(sztd(time_start:time_stop, :), 'omitnan'), 'omitnan') + ([-6 6]) .* median(std(sztd(time_start:time_stop, :), 'omitnan'), 'omitnan'));
                
                plot(t, sztd,'.-'); hold on;
                plot(t, zero2nan(rec(:).getZtd),'k', 'LineWidth', 4);
                %ylim(yl);
                %xlim(t(time_start) + [0 win_size-1] ./ 86400);
                setTimeTicks(4,'dd/mm/yyyy HH:MMPM');
                h = ylabel('ZTD [m]'); h.FontWeight = 'bold';
                grid on;
                h = title(sprintf('Receiver %s ZTD', rec(1).parent.marker_name),'interpreter', 'none'); h.FontWeight = 'bold'; %h.Units = 'pixels'; h.Position(2) = h.Position(2) + 8; h.Units = 'data';
                drawnow;
            end
            
            
        end
        
        function [tropo, time] = getTropoPar(sta_list, par_name)
            % get a tropo parameter among 'ztd', 'zwd', 'pwv', 'zhd'
            %
            % SYNTAX
            %  [tropo, p_time] = sta_list.getAprZhd()
            
            tropo = {};
            time = {};
            for r = 1 : numel(sta_list)
                time{r} = sta_list(r).getTime();
                switch lower(par_name)
                    case 'ztd'
                        [tropo{r}] = sta_list(r).getZtd();
                    case 'zwd'
                        [tropo{r}] = sta_list(r).getZwd();
                        if isempty(tropo{r}) || all(isnan(zero2nan(tropo{r})))
                            [tropo{r}] = sta_list(r).getAprZwd();
                        end
                        
                    case 'gn'
                        [tropo{r}] = sta_list(r).getGradient();
                    case 'ge'
                        [~,tropo{r}] = sta_list(r).getGradient();
                    case 'pwv'
                        [tropo{r}] = sta_list(r).getPwv();
                    case 'zhd'
                        [tropo{r}] = sta_list(r).getAprZhd();
                    case 'nsat'
                        [tropo{r}] = sta_list(r).getNSat();
                end
            end
            
            if numel(tropo) == 1
                tropo = tropo{1};
                time = time{1};
            end
        end
        
        function showTropoPar(sta_list, par_name, new_fig)
            % one function to rule them all
            
            [tropo, t] = sta_list.getTropoPar(par_name);
            if ~iscell(tropo)
                tropo = {tropo};
                t = {t};
            end
            
            rec_ok = false(numel(sta_list), 1);
            for r = 1 : size(sta_list, 2)
                rec_ok(r) = ~isempty(tropo{r});
            end
            
            sta_list = sta_list(rec_ok);
            tropo = tropo(rec_ok);
            t = t(rec_ok);
            
            if numel(sta_list) == 0
                log = Logger.getInstance();
                log.addError('No valid troposphere is present in the receiver list');
            else
                if nargin < 3
                    new_fig = true;
                end                                
                
                if isempty(tropo)
                    sta_list(1).log.addWarning([par_name ' and slants have not been computed']);
                else
                    if new_fig
                        f = figure; f.Name = sprintf('%03d: %s %s', f.Number, par_name, sta_list(1).cc.sys_c); f.NumberTitle = 'off';
                        old_legend = {};
                    else
                        l = legend;
                        old_legend = get(l,'String');
                    end
                    for r = 1 : numel(sta_list)
                        rec = sta_list(r);
                        if new_fig
                            plot(t{r}.getMatlabTime(), zero2nan(tropo{r}'), '.', 'LineWidth', 4, 'Color', Core_UI.getColor(r, size(sta_list, 2))); hold on;
                        else
                            plot(t{r}.getMatlabTime(), zero2nan(tropo{r}'), '.', 'LineWidth', 4); hold on;
                        end
                        outm{r} = rec(1).parent.getMarkerName();
                    end
                    
                    outm = [old_legend, outm];
                    [~, icons] = legend(outm, 'Location', 'NorthEastOutside', 'interpreter', 'none');
                    n_entry = numel(outm);
                    icons = icons(n_entry + 2 : 2 : end);
                    
                    for i = 1 : numel(icons)
                        icons(i).MarkerSize = 16;
                    end
                    
                    %ylim(yl);
                    %xlim(t(time_start) + [0 win_size-1] ./ 86400);
                    setTimeTicks(4,'dd/mm/yyyy HH:MMPM');
                    h = ylabel([par_name ' [m]']); h.FontWeight = 'bold';
                    grid on;
                    h = title(['Receiver ' par_name]); h.FontWeight = 'bold'; %h.Units = 'pixels'; h.Position(2) = h.Position(2) + 8; h.Units = 'data';
                end
            end
        end
        
        function showZhd(this, new_fig)
            if nargin == 1
                new_fig = true;
            end
            this.showTropoPar('ZHD', new_fig)
        end
        
        function showZwd(this, new_fig)
            if nargin == 1
                new_fig = true;
            end
            this.showTropoPar('ZWD', new_fig)
        end
        
        function showZtd(this, new_fig)
            if nargin == 1
                new_fig = true;
            end
            this.showTropoPar('ZTD', new_fig)
        end
        
        
        function showGn(this, new_fig)
            if nargin == 1
                new_fig = true;
            end
            this.showTropoPar('GN', new_fig)
        end
        
        
        function showGe(this, new_fig)
            if nargin == 1
                new_fig = true;
            end
            this.showTropoPar('GE', new_fig)
        end
        
        function slant_td = getSlantTD(this)
            % Get the slant total delay
            % SYNTAX
            %   slant_td = this.getSlantTD();
            
            [mfh, mfw] = this.getSlantMF();
            n_sat = size(mfh,2);
            zwd = this.getZwd();
            apr_zhd = this.getAprZhd();
            [az, el] = this.getAzEl();
            [tgn, tge] = this.getGradient();
            res = this.getResidual();
            
            cotel = zero2nan(cotd(el));
            cosaz = zero2nan(cosd(az));
            sinaz = zero2nan(sind(az));
            slant_td = nan2zero(zero2nan(res) ...
                + zero2nan(repmat(zwd,1,n_sat).*mfw) ...
                + zero2nan(repmat(apr_zhd,1,n_sat).*mfh) ...
                + repmat(tgn,1,n_sat) .* mfw .* cotel .* cosaz ...
                + repmat(tge,1,n_sat) .* mfw .* cotel .* sinaz);
        end
        
        function showPwv(this, new_fig)
            if nargin == 1
                new_fig = true;
            end
            this.showTropoPar('PWV', new_fig)
        end
        
        function showNSat(this, new_fig)
            if nargin == 1
                new_fig = true;
            end
            this.showTropoPar('nsat', new_fig)
        end
        
        function showNSatSS(this)
            % Show number of satellites in view per constellation
            if ~this.isEmpty()
                [n_sat, n_sat_ss] = this.getNSat;
                f = figure; f.Name = sprintf('%03d: nsat SS %s', f.Number, this.parent.getMarkerName4Ch); f.NumberTitle = 'off';
%                 if isfield(n_sat_ss, 'S')
%                     plot(this.getTime.getMatlabTime(), zero2nan(n_sat_ss.S), '.', 'MarkerSize', 40, 'LineWidth', 2); hold on;
%                 end
%                 if isfield(n_sat_ss, 'I')
%                     plot(this.getTime.getMatlabTime(), zero2nan(n_sat_ss.I), '.', 'MarkerSize', 35, 'LineWidth', 2); hold on;
%                 end
%                 if isfield(n_sat_ss, 'C')
%                     plot(this.getTime.getMatlabTime(), zero2nan(n_sat_ss.C), '.', 'MarkerSize', 30, 'LineWidth', 2); hold on;
%                 end
%                 if isfield(n_sat_ss, 'J')
%                     plot(this.getTime.getMatlabTime(), zero2nan(n_sat_ss.J), '.', 'MarkerSize', 25, 'LineWidth', 2); hold on;
%                 end
%                 if isfield(n_sat_ss, 'E')
%                     plot(this.getTime.getMatlabTime(), zero2nan(n_sat_ss.E), '.', 'MarkerSize', 20, 'LineWidth', 2); hold on;
%                 end
%                 if isfield(n_sat_ss, 'R')
%                     plot(this.getTime.getMatlabTime(), zero2nan(n_sat_ss.R), '.', 'MarkerSize', 15, 'LineWidth', 2); hold on;
%                 end
%                 if isfield(n_sat_ss, 'G')
%                     plot(this.getTime.getMatlabTime(), zero2nan(n_sat_ss.G), '.', 'MarkerSize', 10, 'LineWidth', 2); hold on;
%                 end

                % If I'm plotting more than one day smooth the number of satellites
                if (this.getTime.last.getMatlabTime - this.getTime.first.getMatlabTime) > 1
                    for sys_c = this.cc.sys_c
                        plot(this.getTime.getMatlabTime(), splinerMat(this.getTime.getRefTime, zero2nan(n_sat_ss.(sys_c)), 3600), '.-', 'MarkerSize', 10); hold on;
                    end
                    plot(this.getTime.getMatlabTime(), splinerMat(this.getTime.getRefTime, zero2nan(n_sat), 3600), '.-k', 'MarkerSize', 10); hold on;
                else % If I'm plotting less than 24 hours of satellites number                    
                    plot(this.getTime.getMatlabTime(), zero2nan(struct2array(n_sat_ss)), '.-', 'MarkerSize', 10); hold on;
                    plot(this.getTime.getMatlabTime(), zero2nan(n_sat), '.-k', 'MarkerSize', 10);
                end
                setTimeTicks(4,'dd/mm/yyyy HH:MMPM'); h = ylabel('East [cm]'); h.FontWeight = 'bold';

                sys_list = {};
                for i = 1 : numel(this.cc.sys_c)
                    sys_list = [sys_list, {this.cc.sys_c(i)}];
                end
                legend([sys_list, {'All'}]);
                %legend(sys_list);
                ylim([0 (max(serialize(n_sat)) + 1)]);
                grid minor;
                h = title(sprintf('N sat per constellation - %s', this.parent.getMarkerName4Ch),'interpreter', 'none'); h.FontWeight = 'bold';
            end            
        end
        
        function showMedianTropoPar(this, par_name, new_fig)
            % one function to rule them all
            rec_ok = false(size(this,2), 1);
            for r = 1 : size(this, 2)
                rec_ok(r) = any(~isnan(this(:,r).getZtd));
            end
            rec_list = this(:, rec_ok);
            
            if nargin < 3
                new_fig = true;
            end
            
            switch lower(par_name)
                case 'ztd'
                    [tropo] = rec_list.getZtd();
                case 'zwd'
                    [tropo] = rec_list.getZwd();
                case 'pwv'
                    [tropo] = rec_list.getPwv();
                case 'zhd'
                    [tropo] = rec_list.getAprZhd();
            end
            
            if ~iscell(tropo)
                tropo = {tropo};
            end
            if isempty(tropo)
                rec_list(1).log.addWarning([par_name ' and slants have not been computed']);
            else
                if new_fig
                    f = figure; f.Name = sprintf('%03d: Median %s %s', f.Number, par_name, rec_list(1).cc.sys_c); f.NumberTitle = 'off';
                    old_legend = {};
                else
                    l = legend;
                    old_legend = get(l,'String');
                end
                for r = 1 : size(rec_list, 2)
                    rec = rec_list(~rec_list(:,r).isEmpty, r);
                    if ~isempty(rec)
                        switch lower(par_name)
                            case 'ztd'
                                [tropo] = rec.getZtd();
                            case 'zwd'
                                [tropo] = rec.getZwd();
                            case 'pwv'
                                [tropo] = rec.getPwv();
                            case 'zhd'
                                [tropo] = rec.getAprZhd();
                        end
                        [~, ~, ~, h_o] = rec(1).getPosGeodetic();
                        if new_fig
                            plot(h_o, median(tropo,'omitnan'), '.', 'MarkerSize', 25, 'LineWidth', 4, 'Color', Core_UI.getColor(r, size(rec_list, 2))); hold on;
                        else
                            plot(h_o, median(tropo,'omitnan'), '.', 'MarkerSize', 25, 'LineWidth', 4); hold on;
                        end
                        outm{r} = rec(1).parent.getMarkerName();
                    end
                end
                
                outm = [old_legend, outm];
                [~, icons] = legend(outm, 'Location', 'NorthEastOutside', 'interpreter', 'none');
                n_entry = numel(outm);
                icons = icons(n_entry + 2 : 2 : end);
                
                for i = 1 : numel(icons)
                    icons(i).MarkerSize = 16;
                end
                
                %ylim(yl);
                %xlim(t(time_start) + [0 win_size-1] ./ 86400);
                h = ylabel([par_name ' [m]']); h.FontWeight = 'bold';
                h = xlabel('Elevation [m]'); h.FontWeight = 'bold';
                grid on;
                h = title(['Median Receiver ' par_name]); h.FontWeight = 'bold'; %h.Units = 'pixels'; h.Position(2) = h.Position(2) + 8; h.Units = 'data';
            end
        end
        
        function showMedianZhd(this, new_fig)
            if nargin == 1
                new_fig = true;
            end
            this.showMedianTropoPar('ZHD', new_fig)
        end
        
        function showMedianZwd(this, new_fig)
            if nargin == 1
                new_fig = true;
            end
            this.showMedianTropoPar('ZWD', new_fig)
        end
        
        function showMedianZtd(this, new_fig)
            if nargin == 1
                new_fig = true;
            end
            this.showMedianTropoPar('ZTD', new_fig)
        end
        
        function showMedianPwv(this, new_fig)
            if nargin == 1
                new_fig = true;
            end
            this.showMedianTropoPar('PWV', new_fig)
        end
        
        function showZtdSlantRes_p(this, time_start, time_stop)
            if isempty(this.ztd)
                this.log.addWarning('ZTD and slants have not been computed');
            else
                
                id_sync = this.getIdSync();
                
                t = this.time.getEpoch(id_sync).getMatlabTime;
                
                sztd = this.getSlantZTD(this.parent.slant_filter_win);
                sztd = bsxfun(@minus, sztd, this.ztd(id_sync));
                if nargin >= 3
                    if isa(time_start, 'GPS_Time')
                        time_start = find(t >= time_start.first.getMatlabTime(), 1, 'first');
                        time_stop = find(t <= time_stop.last.getMatlabTime(), 1, 'last');
                    end
                    time_start = max(1, time_start);
                    time_stop = min(size(sztd,1), time_stop);
                else
                    time_start = 1;
                    time_stop = size(sztd,1);
                end
                
                %yl = (median(median(sztd(time_start:time_stop, :), 'omitnan'), 'omitnan') + ([-6 6]) .* median(std(sztd(time_start:time_stop, :), 'omitnan'), 'omitnan'));
                
                az = (mod(this.sat.az(id_sync,:) + 180, 360) -180) ./ 180 * pi; az(isnan(az) | isnan(sztd)) = 1e10;
                el = (90 - this.sat.el(id_sync,:)) ./ 180 * pi; el(isnan(el) | isnan(sztd)) = 1e10;
                
                f = figure; f.Name = sprintf('%03d: Slant res', f.Number); f.NumberTitle = 'off';
                polarScatter(az(:), el(:), 25, abs(sztd(:)), 'filled'); hold on;
                caxis(minMax(abs(sztd))); colormap(flipud(hot)); f.Color = [.95 .95 .95]; colorbar();
                h = title(sprintf('Receiver %s ZTD - Slant difference', this.parent.marker_name),'interpreter', 'none'); h.FontWeight = 'bold'; %h.Units = 'pixels'; h.Position(2) = h.Position(2) + 8; h.Units = 'data';
            end
        end
        
        function plotResidual(this)
            figure
            plot(zero2nan(this.sat.res),'.');
        end
    end
    
    %% METHODS UTILITIES FUNCTIONS
    % ==================================================================================================================================================
    
    methods (Access = public)
        function [map, map_fill, n_data_map, az_g, el_g] = getResMap(rec, step, size_conv, sys_c)
            % Export a map containing the residuals
            % This export works better when a sequence of session is passed to it
            % Note: it works one riceiver at a time
            %
            % OUTPUT
            %   snr_map         cartesian map of the mean observed SNR
            %   snr_map_fill    cartesian map of the mean observed SNR filled in polar view
            %   snr_mask        mask of all the position with snr < threshold
            %   n_data_map      number of data used for the mean (obs falling in the cell)
            %   out_map         map of the number of outliers flagged by goGPS per cell
            %
            % SYNTAX
            %   [snr_map, snr_map_fill, snr_mask, n_data_map, out_map] = this.getMeanMapSNR(<step = 0.5>, <size_conv = 21>, <snr_thr = 45>, <sys_c_list>);
            
            use_work = false;
            
            if nargin < 2 || isempty(step)
                step = 0.5;
            end
            if nargin < 3 || isempty(size_conv)
                size_conv = 21;
            end
            
            log = Core.getLogger();
            if nargin < 4 || isempty(sys_c)
                sys_c = rec(r).cc.getAvailableSys;
                sys_c = sys_c(1);
            end
            
            % Create an el/az grid
            [phi_g, az_g] = getGrid(step);
            el_g = phi_g(phi_g > 0);
            
            % [num_occur] = hist(id_map, unique(id_map));
            map = zeros(numel(el_g), numel(az_g));
            n_data_map = zeros(numel(el_g), numel(az_g));
            
            rec.w_bar.createNewBar('Computing map');
            rec.w_bar.setBarLen(numel(rec));
            
            data = abs(rec.getResidual());
            if sys_c == 'A'
                id_keep = 1 : numel(sys);
            else
                [sys, prn] = rec.cc.getSysPrn(1:size(data,2));
                id_keep = false(size(sys));
                for i = 1 : numel(sys)
                    id_keep(i) = contains(sys_c, sys(i));
                end
                data = data(:, id_keep);
            end
            az = rec.sat.az(:, id_keep);
            el = rec.sat.el(:, id_keep);
            
            if ~isempty(data)
                % Extract non NaN serialized data
                data = zero2nan(data);
                id_ok = (~isnan(data));
                
                % Eliminate empty epochs
                az = az(:, sum(id_ok) > 1);
                el = el(:, sum(id_ok) > 1);
                data = data(:, sum(id_ok) > 1);
                
                id_oo = (~isnan(data(:)));
                
                id_az = max(1, ceil(mod(az(id_oo), 360) / step)); % Get the index of the grid
                id_el = (numel(el_g)) - floor(max(0, min(90 - step/2, el(id_oo)) / step)); % Get the index of the grid
                
                id_map = (id_az - 1) * numel(el_g) + id_el;
                data = serialize(data(id_oo));
                for i = 1 : numel(id_map)
                    map(id_map(i)) = map(id_map(i)) + data(i);
                    n_data_map(id_map(i)) = n_data_map(id_map(i)) + 1;
                end
            end
            rec.w_bar.go();
            
            rec.w_bar.close();
            if isempty(data)
                log.addWarning(sprintf('No data found for %s', rec.getMarkerName4Ch));
                map_fill = nan(size(map));
            else
                map(n_data_map(:) > 0) = map(n_data_map(:) > 0) ./ n_data_map(n_data_map(:) > 0);
                map(n_data_map(:) == 0) = nan;
                               
                % Convert map in polar coordinates to allow a better interpolation
                % In principle it is possible to compute directly this polar map
                % This can be implemented some lines above this point
                step_p = step;
                polar_map = ones(ceil(360 / step_p)) * 0;
                polar_map(2 : end - 1, 2 : end - 1) = nan;
                
                dc_g = (90 - el_g) / 90; % declination
                [az_mesh, dc_mesh] = meshgrid(az_g ./ 180 * pi, dc_g);
                x = round((sin(az_mesh) .* dc_mesh) / step_p * 180) + size(polar_map , 1) / 2;
                y = round((cos(az_mesh) .* dc_mesh) / step_p * 180) + size(polar_map , 1) / 2;
                id_p = size(polar_map,1) .* (x(:)) + (y(:)+1); % id of the polar projection corresponding to the cartesian one
                polar_map(id_p) = map(:);
                %polar_map_fill = max(min(snr_map(:)), min(max(snr_map(:)), simpleFill2D(polar_map, isnan(polar_map),  @(dist) exp(-((dist)).^2))));
                polar_map_fill = max(min(map(:)), min(max(map(:)), inpaint_nans(polar_map)));
                if numel(size_conv) > 0 && ~((numel(size_conv) == 1) && size_conv == 0)
                    polar_map_fill = circConv2(polar_map_fill, size_conv);
                end
                map_fill = nan(size(map));
                map_fill(:) = polar_map_fill(id_p);
            end
        end
    end
    
    % ==================================================================================================================================================
    %% STATIC FUNCTIONS used as utilities
    % ==================================================================================================================================================
    methods (Static, Access = public)
        function [p_time, id_sync] = getSyncTimeExpanded(rec, p_rate)
            % Get the common time among all the receivers
            %
            % SYNTAX
            %   [p_time, id_sync] = GNSS_Station.getSyncTimeExpanded(rec, p_rate);
            %
            % EXAMPLE:
            %   [p_time, id_sync] = GNSS_Station.getSyncTimeExpanded(rec, 30);
            
            if sum(~rec.isEmpty_mr) == 0
                % no valid receiver
                p_time = GPS_Time;
                id_sync = [];
            else
                if nargin == 1
                    p_rate = 1e-6;
                end
                
                % prepare reference time
                % processing time will start with the receiver with the last first epoch
                %          and it will stop  with the receiver with the first last epoch
                
                first_id_ok = find(~rec.isEmpty_mr, 1, 'first');
                if ~isempty(first_id_ok)
                    p_time_zero = round(rec(first_id_ok).time.first.getMatlabTime() * 24)/24; % get the reference time
                end
                
                % Get all the common epochs
                t = [];
                for r = 1 : numel(rec)
                    rec_rate = min(1, rec(r).time.getRate);
                    t = [t; round(rec(r).time.getRefTime(p_time_zero) * rec_rate) / rec_rate];
                    % p_rate = lcm(round(p_rate * 1e6), round(rec(r).time.getRate * 1e6)) * 1e-6; % enable this line to sync rates
                end
                t = unique(t);
                
                % If p_rate is specified use it
                if nargin > 1
                    t = intersect(t, (0 : p_rate : t(end) + p_rate)');
                end
                
                % Create reference time
                p_time = GPS_Time(p_time_zero, t);
                id_sync = nan(p_time.length(), numel(rec));
                
                % Get intersected times
                for r = 1 : numel(rec)
                    rec_rate = min(1, rec(r).time.getRate);
                    [~, id1, id2] = intersect(t, round(rec(r).time.getRefTime(p_time_zero) * rec_rate) / rec_rate);
                    id_sync(id1 ,r) = id2;
                end
            end
        end
        
        function [p_time, id_sync] = getSyncTimeTR(sta_list, obs_type, p_rate)
            % Get the common (shortest) time among all the used receivers and the target(s)
            % For each target (obs_type == 0) produce a different cella arrya with the sync of the other receiver
            % e.g.  Reference receivers @ 1Hz, trg1 @1s trg2 @30s
            %       OUTPUT 1 sync @1Hz + 1 sync@30s
            %
            % SYNTAX
            %   [p_time, id_sync] = Receiver.getSyncTimeTR(rec, obs_type, <p_rate>);
            %
            % SEE ALSO:
            %   this.getSyncTimeExpanded
            %
            if nargin < 3
                p_rate = 1e-6;
            end
            if nargin < 2
                % choose the longest as reference
                len = zeros(1, numel(sta_list));
                for r = 1 : numel(sta_list)
                    len(r) = sta_list(r).length;
                end
                obs_type = ones(1, numel(sta_list));
                obs_type(find(len == max(len), 1, 'first')) = 0;
            end
            
            % Do the target(s) as last
            [~, id] = sort(obs_type, 'descend');
            
            % prepare reference time
            % processing time will start with the receiver with the last first epoch
            %          and it will stop  with the receiver with the first last epoch
            
            first_id_ok = find(~sta_list.isEmpty_mr, 1, 'first');
            p_time_zero = round(sta_list(first_id_ok).time.first.getMatlabTime() * 24)/24; % get the reference time
            p_time_start = sta_list(first_id_ok).time.first.getRefTime(p_time_zero);
            p_time_stop = sta_list(first_id_ok).time.last.getRefTime(p_time_zero);
            p_rate = lcm(round(p_rate * 1e6), round(sta_list(first_id_ok).time.getRate * 1e6)) * 1e-6;
            
            p_time = GPS_Time(); % empty initialization
            
            i = 0;
            for r = id
                ref_t{r} = sta_list(r).time.getRefTime(p_time_zero);
                if obs_type(r) > 0 % if it's not a target
                    if ~sta_list(r).isEmpty
                        p_time_start = max(p_time_start,  round(sta_list(r).time.first.getRefTime(p_time_zero) * sta_list(r).time.getRate) / sta_list(r).time.getRate);
                        p_time_stop = min(p_time_stop,  round(sta_list(r).time.last.getRefTime(p_time_zero) * sta_list(r).time.getRate) / sta_list(r).time.getRate);
                        p_rate = lcm(round(p_rate * 1e6), round(sta_list(r).time.getRate * 1e6)) * 1e-6;
                    end
                else
                    % It's a target
                    
                    % recompute the parameters for the ref_time estimation
                    % not that in principle I can have up to num_trg_rec ref_time
                    % in case of multiple targets the reference times should be independent
                    % so here I keep the temporary rt0 rt1 r_rate var
                    % instead of ref_time_start, ref_time_stop, ref_rate
                    pt0 = max(p_time_start, round(sta_list(r).time.first.getRefTime(p_time_zero) * sta_list(r).time.getRate) / sta_list(r).time.getRate);
                    pt1 = min(p_time_stop, round(sta_list(r).time.last.getRefTime(p_time_zero) * sta_list(r).time.getRate) / sta_list(r).time.getRate);
                    pr = lcm(round(p_rate * 1e6), round(sta_list(r).time.getRate * 1e6)) * 1e-6;
                    pt0 = round(pt0*1e6)/1e6;
                    pt0 = ceil(pt0 / pr) * pr;
                    pt1 = floor(pt1 / pr) * pr;
                    
                    % return one p_time for each target
                    i = i + 1;
                    p_time(i) = GPS_Time(p_time_zero, (pt0 : pr : pt1));
                    p_time(i).toUnixTime();
                    
                    id_sync{i} = nan(p_time(i).length, numel(id));
                    for rs = id % for each rec to sync
                        if ~sta_list(rs).isEmpty && ~(obs_type(rs) == 0 && (rs ~= r)) % if it's not another different target
                            [~, id_ref, id_rec] = intersect(round(sta_list(rs).time.getRefTime(p_time_zero) * 1e1)/1e1, (pt0 : pr : pt1));
                            id_sync{i}(id_rec, rs) = id_ref;
                        end
                    end
                end
            end
        end
        
        function data_s = smoothSatData(data_az, data_el, data_in, cs_mat, method, spline_base, max_gap)
            if nargin < 4
                cs_mat = [];
            end
            if nargin < 6 || isempty(spline_base)
                spline_base = 10; % 5 min
            end
            if nargin < 5 || isempty(method)
                method = 'spline';
            end
            if nargin < 7 || isempty(max_gap)
                max_gap = 0;
            end
            if strcmp(method,'spline')
                data_s = data_in;
                for s = 1 : size(data_s, 2)
                    if isempty(cs_mat)
                        lim = getOutliers(~isnan(data_s(:,s)));
                    else
                        lim = getOutliers(~isnan(data_s(:,s)), cs_mat(:,s));
                    end
                    if max_gap > 0
                        lim = limMerge(lim, max_gap);
                    end
                    
                    % remove small intervals
                    %lim((lim(:,2) - lim(:,1)) < spline_base, :) = [];
                    for l = 1 : size(lim, 1)
                        arc_size = lim(l,2) - lim(l,1) + 1;
                        id_arc = lim(l,1) : lim(l,2);
                        id_arc(isnan(data_s(id_arc, s))) = [];
                        data_tmp = data_s(id_arc, s);
                        if length(data_tmp) > 3
                            data_s(id_arc, s) = splinerMat([], data_tmp, min(arc_size, spline_base));
                        end
                    end
                end
            elseif strcmp(method,'poly_quad')
                data_s = data_in;
                for s = 1 : size(data_s, 2)
                    lim = getOutliers(~isnan(data_s(:,s)), cs_mat(:,s));
                    % remove small intervals
                    lim((lim(:,2) - lim(:,1)) < spline_base, :) = [];
                    for l = 1 : size(lim, 1)
                        n_ep =  lim(l,2) - lim(l,1) +1;
                        if n_ep > 4
                            data_tmp = data_s(lim(l,1) : lim(l,2), s);
                            el_tmp = data_el(lim(l,1) : lim(l,2), s);
                            az_tmp = data_az(lim(l,1) : lim(l,2), s);
                            t = [1:n_ep]';
                            A = [ones(n_ep,1) t t.^2];
                            %                             Qxx = cholinv(A'*A);
                            par = A\data_tmp;
                            %                             par = Qxx*A'*data_tmp;
                            quad_mod = A*par;
                            
                            %                             data_coll = data_tmp - quad_mod;
                            %                             s02 = mean(data_coll.^2) / (n_ep -3);
                            %                             Cy_haty_hat = s02*A'*Qxx;
                            %                             Cvv =  0;
                            data_s(lim(l,1) : lim(l,2), s) = splinerMat(te, data_coll , 1) + quad_mod;
                            data_s(lim(l,1) : lim(l,2), s) = quad_mod;
                        end
                    end
                end
            end
        end
    end
end
