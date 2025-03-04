%   CLASS Command Interpreter
% =========================================================================
%
% DESCRIPTION
%   Interpreter of goGPS command instructions
%
% EXAMPLE
%   cmd = Command_Interpreter.getInstance();
%
% FOR A LIST OF CONSTANTs and METHODS use doc Command_Interpreter


%--------------------------------------------------------------------------
%               ___ ___ ___
%     __ _ ___ / __| _ | __|
%    / _` / _ \ (_ |  _|__ \
%    \__, \___/\___|_| |___/
%    |___/                    v 1.0 beta 2
%
%--------------------------------------------------------------------------
%  Copyright (C) 2009-2018 Mirko Reguzzoni, Eugenio Realini
%  Written by:       Gatti Andrea
%  Contributors:     Gatti Andrea, ...
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
%
%--------------------------------------------------------------------------
% 01100111 01101111 01000111 01010000 01010011
%--------------------------------------------------------------------------

classdef Command_Interpreter < handle        
    %% PROPERTIES CONSTANTS
    % ==================================================================================================================================================
    properties (Constant, GetAccess = private)
        OK       = 0;    % No errors
        ERR_UNK  = 1;    % Command unknown
        ERR_NEI  = 2;    % Not Enough Input Parameters
        WRN_TMI  = -3;   % Too Many Inputs
        WRN_MPT  = -100; % Command empty
        
        STR_ERR = {'Commad unknown', ...
            'Not enough input parameters', ...
            'Too many input parameters'};
    end
    %
    %% PROPERTIES COMMAND CONSTANTS
    % ==================================================================================================================================================
    properties (GetAccess = public, SetAccess = private)
        % List of the supported commands
        
        CMD_LOAD        % Load data from the linked RINEX file into the receiver
        CMD_EMPTY       % Reset the receiver content
        CMD_AZEL        % Compute (or update) Azimuth and Elevation
        CMD_BASICPP     % Basic Point positioning with no correction (useful to compute azimuth and elevation)
        CMD_PREPRO      % Pre-processing command
        CMD_CODEPP      % Code point positioning
        CMD_PPP         % Precise point positioning
        CMD_NET         % Network undifferenced solution
        CMD_SEID        % SEID processing (synthesise L2)
        CMD_REMIONO     % SEID processing (reduce L*)
        CMD_KEEP        % Function to keep just some observations into receivers (e.g. rate => constellation)
        CMD_SYNC        % Syncronization among multiple receivers (same rate)
        CMD_OUTDET      % Outlier and cycle-slip detection
        CMD_SHOW        % Display plots and images
        CMD_EXPORT      % Export results
        CMD_PUSHOUT     % push results in output
        CMD_REMSAT      % remove satellites from receivers
        CMD_REMOBS      % Remove some observations from the receiver (given the obs code)
            
        CMD_PINIT       % parallel request slaves
        CMD_PKILL       % parallel kill slaves
        
        KEY_FOR         % For each session keyword
        KEY_PAR         % For each target (parallel) keyword
        KEY_ENDFOR      % For marker end
        KEY_ENDPAR      % Par marker end

        PAR_RATE        % Parameter select rate
        PAR_CUTOFF      % Parameter select cutoff
        PAR_SNRTHR      % Parameter select snrthr
        PAR_SS          % Parameter select constellation
        PAR_SYNC        % Parameter sync
        PAR_IONO    % Paramter to estimate ionosphere
        
        PAR_SLAVE     % number of parallel slaves to request
        
        PAR_S_ALL       % show all plots
        PAR_S_DA        % Data availability
        PAR_S_ENU       % ENU positions
        PAR_S_ENUBSL    % Baseline ENU positions
        PAR_S_XYZ       % XYZ positions
        PAR_S_MAP       % positions on map
        PAR_S_CK        % Clock Error
        PAR_S_SNR       % SNR Signal to Noise Ratio
        PAR_S_OCS       % Outliers and cycle slips
        PAR_S_OCSP      % Outliers and cycle slips (polar plot)
        PAR_S_RES       % Residuals satellite per satellite
        PAR_S_RES_SKY   % Residuals sky plot
        PAR_S_RES_SKYP  % Residuals sky plot (polar plot)
        PAR_S_ZTD       % ZTD
        PAR_S_ZWD       % ZWD
        PAR_S_PWV       % PWV
        PAR_S_PTH       % PTH
        PAR_S_STD       % ZTD Slant
        PAR_S_RES_STD   % Slant Total Delay Residuals (polar plot)
        PAR_E_REC_MAT   % Receiver export parameter matlab format
        PAR_E_REC_RIN   % Receiver export parameter RINEX format
        PAR_E_TROPO_SNX % Tropo export paramter sinex format
        PAR_E_TROPO_MAT % Tropo export paramter mat format
        PAR_E_COO_CRD   % Coordinates in bernese crd format

        PAR_S_SAVE      % flage for saving                
                
        KEY_LIST = {'FOR', 'PAR', 'ENDFOR', 'ENDPAR'};
        CMD_LIST = {'PINIT', 'PKILL', 'LOAD', 'EMPTY', 'AZEL', 'BASICPP', 'PREPRO', 'CODEPP', 'PPP', 'NET', 'SEID', 'REMIONO', 'KEEP', 'SYNC', 'OUTDET', 'SHOW', 'EXPORT', 'PUSHOUT', 'REMSAT', 'REMOBS'};
        PUSH_LIST = {'PPP','NET','CODEPP','AZEL'};
        VALID_CMD = {};
        CMD_ID = [];
        KEY_ID = [];
        % Struct containing cells are not created properly as constant => see init method
    end
    %
    %% PROPERTIES SINGLETON POINTERS
    % ==================================================================================================================================================
    properties % Utility Pointers to Singletons
        log
        core
    end
    %
    %% METHOD CREATOR
    % ==================================================================================================================================================
    methods (Static, Access = public)
        % Concrete implementation.  See Singleton superclass.
        function this = Command_Interpreter(varargin)
            % Core object creator
            this.log = Logger.getInstance();
            this.init(varargin{1});
        end
    end
    
    %
    %% METHODS INIT
    % ==================================================================================================================================================
    methods
        function init(this, core)
            % Define and fill the "CONSTANT" structures of the class
            % Due to MATLAB limits it is not possible to create cells into struct on declaration
            %
            % SYNTAX:
            %   this.init()
            
            % definition of parameters (ToDo: these should be converted into objects)
            % in the definition the character "$" indicate the parameter value
            
            if nargin == 2
                if iscell(core) && ~isempty(core) && ~isempty(core{1})
                    core = core{1};
                end
                if ~isempty(core)
                    this.core = core;
                end
            end
            this.PAR_RATE.name = 'rate';
            this.PAR_RATE.descr = '@<rate>            processing rate in seconds (e.g. @30s, -r=30s)';
            this.PAR_RATE.par = '(\@)|(\-r\=)|(\-\-rate\=)'; % (regexp) parameter prefix: @ | -r= | --rate= 
            this.PAR_RATE.class = 'double';
            this.PAR_RATE.limits = [0.000001 900];
            this.PAR_RATE.accepted_values = [];
            
            this.PAR_CUTOFF.name = 'cut-off';
            this.PAR_CUTOFF.descr = '-e=<elevation>     elevation in degree (e.g. -e=7)';
            this.PAR_CUTOFF.par = '(\-e\=)|(\-\-cutoff\=)'; % (regexp) parameter prefix: @ | -e= | --cutoff= 
            this.PAR_CUTOFF.class = 'double';
            this.PAR_CUTOFF.limits = [0 90];
            this.PAR_CUTOFF.accepted_values = [];

            this.PAR_SNRTHR.name = 'SNR threshold';
            this.PAR_SNRTHR.descr = '-q=<snrthr>        SNR threshold in dbHZ on L1 (e.g. -q=7)';
            this.PAR_SNRTHR.par = '(\-q\=)|(\-\-snrthr\=)'; % (regexp) parameter prefix: @ | -q= | --snrthr= 
            this.PAR_SNRTHR.class = 'double';
            this.PAR_SNRTHR.limits = [0 70];
            this.PAR_SNRTHR.accepted_values = [];

            this.PAR_SS.name = 'constellation';
            this.PAR_SS.descr = '-s=<sat_list>      active constellations (e.g. -s=GRE)';
            this.PAR_SS.par = '(\-s\=)|(\-\-constellation\=)'; % (regexp) parameter prefix: -s --constellation
            this.PAR_SS.class = 'char';
            this.PAR_SS.limits = [];
            this.PAR_SS.accepted_values = [];
            
            this.PAR_SYNC.name = 'sync results';
            this.PAR_SYNC.descr = '--sync             use syncronized time only';
            this.PAR_SYNC.par = '(\-\-sync)';
            this.PAR_SYNC.class = '';
            this.PAR_SYNC.limits = [];
            this.PAR_SYNC.accepted_values = [];
            
            this.PAR_SLAVE.name = '(MANDATORY) Number of slaves';
            this.PAR_SLAVE.descr = '-n=<num_slaves>    minimum number of parallel slaves to request';
            this.PAR_SLAVE.par = '(N)|(-n\=)';
            this.PAR_SLAVE.class = 'double';
            this.PAR_SLAVE.limits = [1 1000];
            this.PAR_SLAVE.accepted_values = [];
            
            this.PAR_IONO.name = 'Reduce for ionosphere delay';
            this.PAR_IONO.descr = 'I reduce for ionosphere delay';
            this.PAR_IONO.par = '(-iono)|(-Iono)|(-IONO)';
            this.PAR_IONO.class = '';
            this.PAR_IONO.limits = [];
            this.PAR_IONO.accepted_values = [];

            % Show plots
            
            this.PAR_S_ALL.name = 'Show all the plots';
            this.PAR_S_ALL.descr = 'SHOWALL';
            this.PAR_S_ALL.par = '(ALL)|(all)';

            this.PAR_S_DA.name = 'Data availability';
            this.PAR_S_DA.descr = 'DA               Data Availability';
            this.PAR_S_DA.par = '(DA)|(\-\-dataAvailability)|(da)';

            this.PAR_S_ENU.name = 'ENU positions';
            this.PAR_S_ENU.descr = 'ENU              East Nord Up positions';
            this.PAR_S_ENU.par = '(ENU)|(enu)';

            this.PAR_S_ENUBSL.name = 'ENU baseline';
            this.PAR_S_ENUBSL.descr = 'ENUBSL           East Nord Up baseline';
            this.PAR_S_ENUBSL.par = '(ENUBSL)|(enu_base)';

            this.PAR_S_XYZ.name = 'XYZ positions';
            this.PAR_S_XYZ.descr = 'XYZ              XYZ Earth Fixed Earth centered positions';
            this.PAR_S_XYZ.par = '(XYZ)|(xyz)';

            this.PAR_S_MAP.name = 'Position on map';
            this.PAR_S_MAP.descr = 'MAP              Position on map';
            this.PAR_S_MAP.par = '(MAP)|(map)';

            this.PAR_S_CK.name = 'Clock Error';
            this.PAR_S_CK.descr = 'CK               Clock errors';
            this.PAR_S_CK.par = '(ck)|(CK)';

            this.PAR_S_SNR.name = 'SNR Signal to Noise Ratio';
            this.PAR_S_SNR.descr = 'SNR              Signal to Noise Ratio (polar plot)';
            this.PAR_S_SNR.par = '(snr)|(SNR)';
            
            this.PAR_S_OCS.name = 'Outliers and cycle slips';
            this.PAR_S_OCS.descr = 'OCS              Outliers and cycle slips';
            this.PAR_S_OCS.par = '(ocs)|(OCS)';
            
            this.PAR_S_OCSP.name = 'Outliers and cycle slips (polar plot)';
            this.PAR_S_OCSP.descr = 'OCSP             Outliers and cycle slips (polar plot)';
            this.PAR_S_OCSP.par = '(ocsp)|(OCSP)';
            
            this.PAR_S_RES.name = 'Residuals plot';
            this.PAR_S_RES.descr = 'RES              Residual plot';
            this.PAR_S_RES.par = '(res)|(RES)';

            this.PAR_S_RES_SKY.name = 'Residuals sky plot';
            this.PAR_S_RES_SKY.descr = 'RES_SKY          Residual sky plot';
            this.PAR_S_RES_SKY.par = '(res_sky)|(RES_SKY)';

            this.PAR_S_RES_SKYP.name = 'Residuals sky plot (polar plot)';
            this.PAR_S_RES_SKYP.descr = 'RES_SKYP         Residual sky plot (polar plot)';
            this.PAR_S_RES_SKYP.par = '(res_skyp)|(RES_SKYP)';

            this.PAR_S_ZTD.name = 'ZTD';
            this.PAR_S_ZTD.descr = 'ZTD              Zenith Total Delay';
            this.PAR_S_ZTD.par = '(ztd)|(ZTD)';

            this.PAR_S_ZWD.name = 'ZWD';
            this.PAR_S_ZWD.descr = 'ZWD              Zenith Wet Delay';
            this.PAR_S_ZWD.par = '(zwd)|(ZWD)';

            this.PAR_S_PWV.name = 'PWV';
            this.PAR_S_PWV.descr = 'PWV              Precipitable Water Vapour';
            this.PAR_S_PWV.par = '(pwv)|(PWV)';

            this.PAR_S_PTH.name = 'PTH';
            this.PAR_S_PTH.descr = 'PTH              Pressure / Temperature / Humidity';
            this.PAR_S_PTH.par = '(pth)|(PTH)';

            this.PAR_S_STD.name = 'ZTD Slant';
            this.PAR_S_STD.descr = 'STD              Zenith Total Delay with slants';
            this.PAR_S_STD.par = '(std)|(STD)';

            this.PAR_S_RES_STD.name = 'Slant Total Delay Residuals (polar plot)';
            this.PAR_S_RES_STD.descr = 'RES_STD          Slants Total Delay residuals (polar plot)';
            this.PAR_S_RES_STD.par = '(res_std)|(RES_STD)';

            this.PAR_E_REC_MAT.name = 'Receiver Matlab format';
            this.PAR_E_REC_MAT.descr = 'REC_MAT          Receiver object as .mat file';
            this.PAR_E_REC_MAT.par = '(rec_mat)|(REC_MAT)';
            this.PAR_E_REC_MAT.accepted_values = {};

            this.PAR_E_REC_RIN.name = 'RINEX v3';
            this.PAR_E_REC_RIN.descr = 'REC_RIN          Rinex file containing the actual data stored in rec.work';
            this.PAR_E_REC_RIN.par = '(REC_RIN)|(rec_rin)|(rin3)|(RIN3)';
            this.PAR_E_REC_RIN.accepted_values = {};

            this.PAR_E_TROPO_SNX.name = 'TROPO Sinex';
            this.PAR_E_TROPO_SNX.descr = 'TRP_SNX          Tropo parameters as SINEX file';
            this.PAR_E_TROPO_SNX.par = '(trp_snx)|(TRP_SNX)';
            this.PAR_E_TROPO_SNX.accepted_values = {'ZTD','GN','GE','ZWD','PWV','P','T','H'};

            this.PAR_E_TROPO_MAT.name = 'TROPO Matlab format';
            this.PAR_E_TROPO_MAT.descr = 'TRP_MAT          Tropo parameters matlab as .mat file';
            this.PAR_E_TROPO_MAT.par = '(trp_mat)|(TRP_MAT)';
            this.PAR_E_TROPO_MAT.accepted_values = {};
                        
            this.PAR_E_COO_CRD.name = 'Coordinates bernese CRD format';
            this.PAR_E_COO_CRD.descr = 'COO_CRD          Coordinates Bernese .CRD file';
            this.PAR_E_COO_CRD.par = '(coo_crd)|(COO_CRD)';
            this.PAR_E_COO_CRD.class = '';
            this.PAR_E_COO_CRD.limits = [];
            this.PAR_E_COO_CRD.accepted_values = [];
            
            % definition of commands
            
            new_line = [char(10) '             ']; %#ok<CHARTEN>
            this.CMD_LOAD.name = {'LOAD', 'load'};
            this.CMD_LOAD.descr = 'Import the RINEX file linked with this receiver';
            this.CMD_LOAD.rec = 'T';
            this.CMD_LOAD.par = [this.PAR_SS, this.PAR_RATE];

            this.CMD_EMPTY.name = {'EMPTY', 'empty'};
            this.CMD_EMPTY.descr = 'Empty the receiver';
            this.CMD_EMPTY.rec = 'T';
            this.CMD_EMPTY.par = [];

            this.CMD_AZEL.name = {'AZEL', 'UPDATE_AZEL', 'update_azel', 'azel'};
            this.CMD_AZEL.descr = 'Compute Azimuth and elevation ';
            this.CMD_AZEL.rec = 'T';
            this.CMD_AZEL.par = [];

            this.CMD_BASICPP.name = {'BASICPP', 'PP', 'basic_pp', 'pp'};
            this.CMD_BASICPP.descr = 'Basic Point positioning with no correction';
            this.CMD_BASICPP.rec = 'T';
            this.CMD_BASICPP.par = [this.PAR_RATE this.PAR_SS];

            this.CMD_PREPRO.name = {'PREPRO', 'pre_processing'};
            this.CMD_PREPRO.descr = ['Code positioning, computation of satellite positions and various' new_line 'corrections'];
            this.CMD_PREPRO.rec = 'T';
            this.CMD_PREPRO.par = [this.PAR_RATE this.PAR_SS];
            
            this.CMD_CODEPP.name = {'CODEPP', 'ls_code_point_positioning'};
            this.CMD_CODEPP.descr = 'Code positioning';
            this.CMD_CODEPP.rec = 'T';
            this.CMD_CODEPP.par = [this.PAR_RATE this.PAR_SS];
            
            this.CMD_PPP.name = {'PPP', 'precise_point_positioning'};
            this.CMD_PPP.descr = 'Precise Point Positioning using carrier phase observations';
            this.CMD_PPP.rec = 'T';
            this.CMD_PPP.par = [this.PAR_RATE this.PAR_SS this.PAR_SYNC];
            
            this.CMD_NET.name = {'NET', 'network'};
            this.CMD_NET.descr = 'Network solution using undifferenced carrier phase observations';
            this.CMD_NET.rec = 'TR';
            this.CMD_NET.par = [this.PAR_RATE this.PAR_SS this.PAR_SYNC this.PAR_E_COO_CRD this.PAR_IONO];
            
            this.CMD_SEID.name = {'SEID', 'synthesise_L2'};
            this.CMD_SEID.descr = ['Generate a Synthesised L2 on a target receiver ' new_line 'using n (dual frequencies) reference stations'];
            this.CMD_SEID.rec = 'RT';
            this.CMD_SEID.par = [];
            
            this.CMD_REMIONO.name = {'REMIONO', 'remove_iono'};
            this.CMD_REMIONO.descr = ['Remove ionosphere from observations on a target receiver ' new_line 'using n (dual frequencies) reference stations'];
            this.CMD_REMIONO.rec = 'RT';
            this.CMD_REMIONO.par = [];
            
            this.CMD_KEEP.name = {'KEEP'};
            this.CMD_KEEP.descr = ['Keep in the object the data of a certain constallation' new_line 'at a certain rate'];
            this.CMD_KEEP.rec = 'T';
            this.CMD_KEEP.par = [this.PAR_RATE this.PAR_SS this.PAR_CUTOFF this.PAR_SNRTHR];
            
            this.CMD_SYNC.name = {'SYNC'};
            this.CMD_SYNC.descr = ['Syncronize all the receivers at the same rate ' new_line '(with the minimal data span)'];
            this.CMD_SYNC.rec = 'T';
            this.CMD_SYNC.par = [this.PAR_RATE];
            
            this.CMD_OUTDET.name = {'OUTDET', 'outlier_detection', 'cycle_slip_detection'};
            this.CMD_OUTDET.descr = 'Force outlier and cycle slip detection';
            this.CMD_OUTDET.rec = 'T';
            this.CMD_OUTDET.par = [];

            this.CMD_SHOW.name = {'SHOW'};
            this.CMD_SHOW.descr = 'Display various plots / images';
            this.CMD_SHOW.rec = 'T';
            this.CMD_SHOW.par = [this.PAR_S_DA this.PAR_S_ENU this.PAR_S_ENUBSL this.PAR_S_XYZ this.PAR_S_CK this.PAR_S_SNR this.PAR_S_OCS this.PAR_S_OCSP this.PAR_S_RES this.PAR_S_RES_SKY this.PAR_S_RES_SKYP this.PAR_S_PTH this.PAR_S_ZTD this.PAR_S_ZWD this.PAR_S_PWV this.PAR_S_STD this.PAR_S_RES_STD];

            this.CMD_EXPORT.name = {'EXPORT', 'export', 'export'};
            this.CMD_EXPORT.descr = 'Export';
            this.CMD_EXPORT.rec = 'T';
            this.CMD_EXPORT.par = [this.PAR_E_REC_MAT this.PAR_E_REC_RIN this.PAR_E_TROPO_SNX this.PAR_E_TROPO_MAT];
            
            this.CMD_PUSHOUT.name = {'PUSHOUT', 'pushout'};
            this.CMD_PUSHOUT.descr = 'Push results in output';
            this.CMD_PUSHOUT.rec = 'T';
            this.CMD_PUSHOUT.par = [];

            this.CMD_PINIT.name = {'PINIT', 'pinit'};
            this.CMD_PINIT.descr = 'Parallel init => r n slaves';
            this.CMD_PINIT.rec = '';
            this.CMD_PINIT.par = [this.PAR_SLAVE];

            this.CMD_PKILL.name = {'PKILL', 'pkill'};
            this.CMD_PKILL.descr = 'Parallel kill all the slaves';
            this.CMD_PKILL.rec = '';
            
            this.CMD_PKILL.par = [];
            
            this.CMD_REMSAT.name = {'REMSAT', 'remsat'};
            this.CMD_REMSAT.descr = ['Remove satellites, format: <1ch sat. sys. (GREJCI)><2ch sat. prn>' new_line 'e.g. REMSAT T1 G04,G29,J04'];
            this.CMD_REMSAT.rec = 'T';
            this.CMD_REMSAT.key = 'S'; % fake not used key, indicate thet there's one mandatory parameter
            this.CMD_REMSAT.par = [];

            this.CMD_REMOBS.name = {'REMOBS', 'remobs'};
            this.CMD_REMOBS.descr = ['Remove observation, format: <1ch obs. type (CPDS)><1ch freq><1ch tracking>' new_line 'e.g. REMOBS T1 D,S2,L2C'];
            this.CMD_REMOBS.rec = 'T';
            this.CMD_REMOBS.key = 'O'; % fake not used key, indicate thet there's one mandatory parameter
            this.CMD_REMOBS.par = [];

            this.KEY_FOR.name = {'FOR', 'for'};
            this.KEY_FOR.descr = 'For session loop start';
            this.KEY_FOR.rec = '';
            this.KEY_FOR.key = 'S';
            this.KEY_FOR.par = [];

            this.KEY_PAR.name = {'PAR', 'par'};
            this.KEY_PAR.descr = ['Parallel section start (run on targets)' new_line 'use T$ as target in this section'];
            this.KEY_PAR.rec = '';
            this.KEY_PAR.key = 'TP';
            this.KEY_PAR.par = [];

            this.KEY_ENDFOR.name = {'ENDFOR', 'END_FOR', 'end_for'};
            this.KEY_ENDFOR.descr = 'For loop end';
            this.KEY_ENDFOR.rec = '';
            this.KEY_ENDFOR.key = '';
            this.KEY_ENDFOR.par = [];

            this.KEY_ENDPAR.name = {'ENDPAR', 'END_PAR', 'end_par'};
            this.KEY_ENDPAR.descr = 'Parallel section end';
            this.KEY_ENDPAR.rec = '';
            this.KEY_ENDPAR.key = '';
            this.KEY_ENDPAR.par = [];

            % When adding a command remember to add it to the valid_cmd list
            % Create the launcher exec function
            % and modify the method exec to allow execution
            this.VALID_CMD = {};
            this.CMD_ID = [];
            this.KEY_ID = [];
            for c = 1 : numel(this.CMD_LIST)
                this.VALID_CMD = [this.VALID_CMD(:); this.(sprintf('CMD_%s', this.CMD_LIST{c})).name(:)];
                this.CMD_ID = [this.CMD_ID, c * ones(size(this.(sprintf('CMD_%s', this.CMD_LIST{c})).name))];
                this.(sprintf('CMD_%s', this.CMD_LIST{c})).id = c;
            end
            for c = 1 : numel(this.KEY_LIST)
                this.VALID_CMD = [this.VALID_CMD(:); this.(sprintf('KEY_%s', this.KEY_LIST{c})).name(:)];
                this.CMD_ID = [this.CMD_ID, (c + numel(this.CMD_LIST)) * ones(size(this.(sprintf('KEY_%s', this.KEY_LIST{c})).name))];
                this.KEY_ID = [this.KEY_ID, (c + numel(this.CMD_LIST)) * ones(size(this.(sprintf('KEY_%s', this.KEY_LIST{c})).name))];
                this.(sprintf('KEY_%s', this.KEY_LIST{c})).id = (c + numel(this.CMD_LIST));
            end            
        end
        
        function str = getHelp(this)
            % Get a string containing the "help" description to all the supported commands
            %
            % SYNTAX:
            %   str = this.getHelp()
            str = sprintf('Accepted commands:\n');
            str = sprintf('%s--------------------------------------------------------------------------------\n', str);
            for c = 1 : numel(this.CMD_LIST)
                cmd_name = this.(sprintf('CMD_%s', this.CMD_LIST{c})).name{1};
                str = sprintf('%s - %s\n', str, cmd_name);
            end
            str = sprintf('%s\nCommands description:\n', str);
            str = sprintf('%s--------------------------------------------------------------------------------\n', str);
            for c = 1 : numel(this.CMD_LIST)
                cmd = this.(sprintf('CMD_%s', this.CMD_LIST{c}));
                str = sprintf('%s - %s%s%s\n', str, cmd.name{1}, ones(1, 10 - numel(cmd.name{1})) * ' ', cmd.descr);
                if ~isempty(cmd.rec)
                    str = sprintf('%s\n%s%s', str, ones(1, 13) * ' ', 'Mandatory receivers:');
                    if numel(cmd.rec) > 1
                        rec_par = sprintf('%c%s', cmd.rec(1), sprintf(', %c', cmd.rec(2:end)));
                    else
                        rec_par = cmd.rec(1);
                    end
                    str = sprintf('%s %s\n', str, rec_par);
                end
                
                if ~isempty(cmd.par)
                    str = sprintf('%s\n%s%s\n', str, ones(1, 13) * ' ', 'Parameters:');
                    for p = 1 : numel(cmd.par)
                        str = sprintf('%s%s%s\n', str, ones(1, 15) * ' ', cmd.par(p).descr);
                    end
                end
                str = sprintf('%s\n--------------------------------------------------------------------------------\n', str);
            end
            for c = 1 : numel(this.KEY_LIST)
                cmd = this.(sprintf('KEY_%s', this.KEY_LIST{c}));
                str = sprintf('%s - %s%s%s\n', str, cmd.name{1}, ones(1, 10-numel(cmd.name{1})) * ' ', cmd.descr);
                if ~isempty(cmd.rec)
                    str = sprintf('%s\n%s%s', str, ones(1, 13) * ' ', 'Mandatory receivers:');
                    if numel(cmd.rec) > 1
                        rec_par = sprintf('%c%s', cmd.rec(1), sprintf(', %c', cmd.rec(2:end)));
                    else
                        rec_par = cmd.rec(1);
                    end
                    str = sprintf('%s %s\n', str, rec_par);
                end
                
                if ~isempty(cmd.key)
                    str = sprintf('%s\n%s%s', str, ones(1, 13) * ' ', 'Mandatory session:');
                    if numel(cmd.key) > 1
                        rec_par = sprintf('%c%s', cmd.key(1), sprintf(', %c', cmd.key(2:end)));
                    else
                        rec_par = cmd.key(1);
                    end
                    str = sprintf('%s %s\n', str, rec_par);
                end
                
                if ~isempty(cmd.par)
                    str = sprintf('%s\n%s%s\n', str, ones(1, 13) * ' ', 'Optional parameters:');
                    for p = 1 : numel(cmd.par)
                        str = sprintf('%s%s%s\n', str, ones(1, 15) * ' ', cmd.par(p).descr);
                    end
                end
                str = sprintf('%s\n--------------------------------------------------------------------------------\n', str);
            end
            
            str = sprintf(['%s\n   Note: "T" refers to Target receiver' ...
                '\n         "R" refers to reference receiver' ...
                '\n         Receivers can be identified with their id (as defined in "obs_name")' ...
                '\n         It is possible to provide multiple receivers (e.g. T* or T1:4 or T1,3:5)\n' ...
                ], str);
            
        end
        
        function str = getExamples(this)
            % Get a string containing the "examples" of processing
            %
            % SYNTAX:
            %   str = this.getHelp()
            str = sprintf(['# PPP processing', ...
                '\n# @5 seconds rate GPS GALILEO', ...
                '\n\n FOR S*' ...
                '\n    LOAD T* @5s -s=GE', ...
                '\n    PREPRO T*', ...
                '\n    PPP T*', ...
                '\n ENDFOR', ...
                '\n SHOW T* ZTD', ...
                '\n EXPORT T* TRP_SNX', ...
                '\n\n# Network undifferenced processing', ...
                '\n# @30 seconds rate GPS only', ...
                '\n# processing all sessions', ...
                '\n# using receivers 1,2 as reference\n# for the mean', ...                
                '\n\n FOR S*' ...
                '\n    LOAD T* @30s -s=G', ...
                '\n    PREPRO T*', ...
                '\n    PPP T1:2', ...
                '\n    NET T* R1,2', ...
                '\n ENDFOR', ...
                '\n SHOW T* MAP', ...
                '\n SHOW T* ENUBSL', ...
                '\n\n# Parallel Baseline solution with 16 slaves\n# The reference is the receiver 1', ...
                '\n\n PINIT N16' ...
                '\n FOR S*' ...
                '\n    LOAD T1' ...
                '\n    PREPRO T1' ...
                '\n    PAR T2:17 P1' ...
                '\n       OUTDET T1' ...
                '\n       LOAD T$' ...
                '\n       PREPRO T$' ...
                '\n       NET T1,$ R1' ...
                '\n    ENDPAR' ...
                '\n ENDFOR' ...
                '\n\n# Parallel PPP with 3 slaves\n# killing workers at the end\n# of processing', ...
                '\n\n PINIT -n=3' ...
                '\n FOR S*' ...
                '\n    PAR T*' ...
                '\n       LOAD T$ @30s -s=G', ...
                '\n       PREPRO T$', ...
                '\n       PPP T$', ...
                '\n    ENDPAR' ...                
                '\n ENDFOR', ...
                '\n PKILL', ...
                '\n SHOW T* ZTD', ...PINIT N6
                '\n\n# PPP + SEID processing', ...
                '\n# 4 reference stations \n# + one L1 target', ...
                '\n# @30 seconds rate GPS', ...
                '\n\n FOR S*' ...
                '\n    LOAD T* @30s -s=G', ...
                '\n    PREPRO T*', ...
                '\n    PPP T1:4', ...
                '\n    SEID R1:4 T5', ...
                '\n    PPP R5', ...
                '\n ENDFOR', ...
                '\n SHOW T* ZTD']);
        end
    end
    %
    %% METHODS EXECUTE
    % ==================================================================================================================================================
    % methods to execute a set of goGPS Commands
    methods         
        function exec(this, rec, cmd_list, level)
            % run a set of commands (divided in cells of cmd_list)
            %
            % SYNTAX:
            %   this.exec(rec, cmd_list, level)
            if nargin < 3
                state = Core.getState();
                cmd_list = state.getCommandList();
            end
            if ~iscell(cmd_list)
                cmd_list = {cmd_list};
            end            
            [cmd_list, ~, ~, ~, trg_list, cmd_lev] = this.fastCheck(cmd_list);
            if nargin < 4 || isempty(level)
                level = cmd_lev;
            end

            t0 = tic();
            
            % run each line
            l = 0;
            while l < numel(cmd_list)
                l = l + 1;
            
                tok = regexp(cmd_list{l},'[^ ]*', 'match'); % get command tokens
                this.log.newLine();
                this.log.addMarkedMessage(sprintf('Executing: %s', cmd_list{l}));
                t1 = tic;
                this.log.simpleSeparator([], [0.4 0.4 0.4]);
                
                % Init parallel controller when a parallel section is found
                switch tok{1}
                    case this.KEY_PAR.name 
                        [id_pass, found] = this.getMatchingRec(rec, tok, 'P');
                        if ~found
                            id_pass = [];
                        end
                        this.core.activateParallelWorkers(id_pass);
                end
                
                n_workers = 0;
                if ~isempty(trg_list{l})
                    % The user wants to go parallel, but are workers active?
                    gom = Parallel_Manager.getInstance;
                    n_workers = gom.getNumWorkers;
                    if n_workers == 0
                        this.log.addWarning('No parallel workers have been found\n Launch some slaves!!!\nrunning in serial mode');                        
                    end
                end
                % go parallel
                % Get the parallel target => remove not available targets
                tmp = trg_list{l};
                trg_list{l} = tmp(tmp <= numel(rec));
                
                % find the last command of this parallel section
                last_par_id = find((cmd_lev(l : end) - cmd_lev(l)) < 0, 1, 'first');
                if isempty(last_par_id)
                    last_par_id = numel(cmd_lev);
                else
                    last_par_id = last_par_id + l - 2;
                end
                par_cmd_id = (l + 1) : last_par_id;
                
                if n_workers > 0
                    par_cmd_list = cmd_list(par_cmd_id); % command list for the parallel worker
                    
                    gom.orderProcessing(par_cmd_list, trg_list{l});
                    l = par_cmd_id(end);
                    rec = Core.getRecList();
                else
                    if ~isempty(trg_list)
                        if ~isempty(trg_list{l})
                            rec_list = sprintf('%d%s',trg_list{l}(1), sprintf(',%d',trg_list{l}(2:end)));
                            for c = (l + 1) : last_par_id
                                cmd_list{c} = strrep(cmd_list{c}, '$', rec_list);
                            end
                        end
                    end
                    
                    switch upper(tok{1})
                        case this.CMD_PINIT.name                % PINIT
                            this.runParInit(tok(2:end));
                        case this.CMD_PKILL.name                % PKILL
                            this.runParKill(tok(2:end));
                        case this.CMD_LOAD.name                 % LOAD
                            this.runLoad(rec, tok(2:end));
                        case this.CMD_EMPTY.name                % EMPTY
                            this.runEmpty(rec, tok(2:end));
                        case this.CMD_AZEL.name                 % AZEL
                            this.runUpdateAzEl(rec, tok(2:end));
                        case this.CMD_BASICPP.name              % BASICPP
                            this.runBasicPP(rec, tok(2:end));
                        case this.CMD_PREPRO.name               % PREP
                            this.runPrePro(rec, tok(2:end));
                        case this.CMD_CODEPP.name               % CODEPP
                            this.runCodePP(rec, tok(2:end));
                        case this.CMD_PPP.name                  % PPP
                            this.runPPP(rec, tok(2:end));
                        case this.CMD_REMSAT.name               % REM SAT
                            this.runRemSat(rec, tok(2:end));
                        case this.CMD_REMOBS.name               % REM OBS
                            this.runRemObs(rec, tok(2:end));
                        case this.CMD_NET.name                  % NET
                            this.runNet(rec, tok(2:end));
                        case this.CMD_SEID.name                 % SEID
                            this.runSEID(rec, tok(2:end));
                        case this.CMD_REMIONO.name              % REMIONO
                            this.runRemIono(rec, tok(2:end));
                        case this.CMD_KEEP.name                 % KEEP
                            this.runKeep(rec.getWork(), tok(2:end));
                        case this.CMD_SYNC.name                 % SYNC
                            this.runSync(rec, tok(2:end));
                        case this.CMD_OUTDET.name               % OUTDET
                            this.runOutDet(rec, tok);
                        case this.CMD_SHOW.name                 % SHOW
                            this.runShow(rec, tok, level(l));
                        case this.CMD_EXPORT.name               % EXPORT
                            this.runExport(rec, tok, level(l));
                        case this.CMD_PUSHOUT.name              % PUSHOUT
                            this.runPushOut(rec, tok);
                    end
                end
                if toc(t1) > 1
                    this.log.newLine();
                    this.log.addMessage(this.log.indent(sprintf('%s executed in %.3f seconds', cmd_list{l}, toc(t1))));
                    this.log.newLine();
                end
            end
            if (toc(t0) > 1) && (numel(cmd_list) > 1)
                this.log.addMessage(this.log.indent('--------------------------------------------------'));
                this.log.addMessage(this.log.indent(sprintf(' Command block execution done in %.3f seconds', toc(t0))));
                this.log.addMessage(this.log.indent('--------------------------------------------------'));
            end
        end
    end
    %
    %% METHODS EXECUTE (PRIVATE)
    % ==================================================================================================================================================
    % methods to execute a set of goGPS Commands
    methods (Access = public)    
        
        function runParInit(this, tok)
            % Load the RINEX file into the object
            %
            % SYNTAX
            %   this.runParInit(tok)
            
            [n_slaves, found] = this.getNumericPar(tok, this.PAR_SLAVE.par);
            Parallel_Manager.requestSlaves(round(n_slaves));
        end
        
        function runParKill(this, tok)
            % Load the RINEX file into the object
            %
            % SYNTAX
            %   this.runParKill(tok)
            Parallel_Manager.killAll();
        end
        
        function runLoad(this, rec, tok)
            % Load the RINEX file into the object
            %
            % INPUT
            %   rec     list of rec objects
            %
            % SYNTAX
            %   this.load(rec)
            
            [id_trg, found] = this.getMatchingRec(rec, tok, 'T');
            if ~found
                this.log.addWarning('No target found -> nothing to do');
            else
                [sys_list, sys_found] = this.getConstellation(tok);
                for r = id_trg
                    this.log.newLine();
                    this.log.addMarkedMessage(sprintf('Importing data for receiver %d: %s', r, rec(r).getMarkerName()));
                    this.log.smallSeparator();
                    this.log.newLine();
                    state = Core.getState();
                    if sys_found
                        state.cc.setActive(sys_list);
                    end
                    [rate, found] = this.getNumericPar(tok, this.PAR_RATE.par);
                    if ~found
                        rate = []; % get the rate of the RINEX
                    end
                    cur_session = Core.getCurrentSession();
                    if state.isRinexSession()
                        rec(r).importRinexLegacy(this.core.state.getRecPath(r, cur_session), rate);
                        rec(r).work.loaded_session = this.core.getCurSession();
                    else
                        [session_limits, out_limits] = state.getSessionLimits(cur_session);
                        if out_limits.length < 2 || ~this.core.rin_list(r).hasObsInSession(out_limits.first, out_limits.last);
                            this.log.addMessage(sprintf('No observations are available for receiver %s in session %d', rec(r).getMarkerName4Ch, cur_session));
                        else
                            rec(r).importRinexes(this.core.rin_list(r).getCopy(), session_limits.first, session_limits.last, rate);
                            rec(r).work.loaded_session = cur_session;
                            rec(r).work.setOutLimits(out_limits.first, out_limits.last);
                        end
                    end
                end
            end
        end
        
        function runEmpty(this, rec, tok)
            % Reset (empty) the receiver
            %
            % INPUT
            %   rec     list of rec objects
            %
            % SYNTAX
            %   this.empty(rec)
            
            [id_trg, found] = this.getMatchingRec(rec, tok, 'T');
            if ~found
                this.log.addWarning('No target found -> nothing to do');
            else
                for r = id_trg
                    this.log.newLine();
                    this.log.addMarkedMessage(sprintf('Empty the receiver %d: %s', r, rec(r).getMarkerName()));
                    this.log.smallSeparator();
                    this.log.newLine();
                    rec(r).resetOut();
                    rec(r).work.resetWorkSpace();
                end
            end
        end
        
        function runPrePro(this, rec, tok)
            % Execute Pre processing
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runPrePro(rec, tok)
            
            [id_trg, found] = this.getMatchingRec(rec, tok, 'T');
            if ~found
                this.log.addWarning('No target found -> nothing to do');
            else
                [sys_list, sys_found] = this.getConstellation(tok);
                for r = id_trg
                    this.log.newLine();
                    this.log.addMarkedMessage(sprintf('Pre-processing on receiver %d: %s', r, rec(r).getMarkerName()));
                    this.log.smallSeparator();
                    this.log.newLine();
                    if rec(r).work.loaded_session ~=  this.core.getCurSession()
                        if sys_found
                            state = Core.getCurrentSettings();
                            state.cc.setActive(sys_list);
                        end
                        if this.core.state.isRinexSession()
                            this.runLoad(rec, tok);
                        else
                            this.runLoad(rec, tok);
                        end
                    end
                    if sys_found
                        rec(r).work.preProcessing(sys_list);
                    else
                        rec(r).work.preProcessing();
                    end
                end
            end
        end
        
        function runUpdateAzEl(this, rec, tok)
            % Execute Computation of azimuth and elevation
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runUpdateAzEl(rec, tok)
            
            [id_trg, found] = this.getMatchingRec(rec, tok, 'T');
            if ~found
                this.log.addWarning('No target found -> nothing to do');
            else
                [sys_list, sys_found] = this.getConstellation(tok);
                for r = id_trg
                    this.log.newLine();
                    this.log.addMarkedMessage(sprintf('Computing azimuth and elevation for receiver %d: %s', r, rec(r).getMarkerName()));
                    this.log.smallSeparator();
                    this.log.newLine();                    
                    if rec(r).isEmpty
                        if sys_found
                            state = Core.getCurrentSettings();
                            state.cc.setActive(sys_list);
                        end
                        rec(r).work.load();
                    end
                    rec(r).work.updateAzimuthElevation();
                    %rec(r).work.pushResult();
                end
            end
        end
        
        function runPushOut(this, rec, tok)
            % Execute Computation of azimuth and elevation
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runUpdateAzEl(rec, tok)
            
            [id_trg, found] = this.getMatchingRec(rec, tok, 'T');
            if ~found
                this.log.addWarning('No target found -> nothing to do');
            else
                for i = 1 : length(id_trg)
                    rec(id_trg(i)).work.pushResult();
                end
            end
        end
        
        function runBasicPP(this, rec, tok)
            % Execute Basic Point positioning with no correction (useful to compute azimuth and elevation)
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.basicPP(rec, tok)
            
            [id_trg, found] = this.getMatchingRec(rec, tok, 'T');
            if ~found
                this.log.addWarning('No target found -> nothing to do');
            else
                [sys_list, sys_found] = this.getConstellation(tok);
                for r = id_trg
                    this.log.newLine();
                    this.log.addMarkedMessage(sprintf('Computing basic position for receiver %d: %s', r, rec(r).getMarkerName()));
                    this.log.smallSeparator();
                    this.log.newLine();
                    if rec(r).isEmpty
                        if sys_found
                            state = Core.getCurrentSettings();
                            state.cc.setActive(sys_list);
                        end
                        rec(r).load();
                    end
                    if sys_found
                        rec(r).computeBasicPosition(sys_list);
                    else
                        rec(r).computeBasicPosition();
                    end
                end
            end
        end

        function runPPP(this, rec, tok)
            % Execute Precise Point Positioning
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runPPP(rec, tok)
            [id_trg, found] = this.getMatchingRec(rec, tok, 'T');
            if ~found
                this.log.addWarning('No target found -> nothing to do');
            else
                [sys_list, sys_found] = this.getConstellation(tok);
                for r = id_trg
                    if rec(r).work.isStatic
                        this.log.newLine();
                        this.log.addMarkedMessage(sprintf('StaticPPP on receiver %d: %s', r, rec(r).getMarkerName()));
                        this.log.smallSeparator();
                        this.log.newLine();
                        if sys_found
                            rec(r).work.staticPPP(sys_list);
                        else
                            rec(r).work.staticPPP();
                        end
                    else
                        this.log.addError('PPP for moving receiver not yet implemented :-(');
                    end
                end
            end
        end
        
        function runRemSat(this, rec, tok)
            % Remove satelites from receivers
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runRemSat(rec, tok)
            [id_trg, found] = this.getMatchingRec(rec, tok, 'T');
            if ~found
                this.log.addWarning('No target found -> nothing to do');
            else
                s_idx = 2;
                for r = id_trg
                    sats = strsplit(tok{s_idx},',');
                    for s = 1 : length(sats)
                        sys_c = sats{s}(1);
                        prn = str2double(sats{s}(2:3));
                        rec(r).work.remSat(sys_c, prn);
                    end
                end
            end
        end

        function runRemObs(this, rec, tok)
            % Remove observation from receivers
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runRemObs(rec, tok)
            [id_trg, found] = this.getMatchingRec(rec, tok, 'T');
            if ~found
                this.log.addWarning('No target found -> nothing to do');
            else
                s_idx = 2;
                for r = id_trg
                    if ~isempty(rec(r)) && ~(rec(r).isEmptyWork_mr)
                        obs_type = strsplit(tok{s_idx},',');
                        id = [];
                        for o = 1 : length(obs_type)
                            id = [id; rec(r).work.findObservableByFlag(obs_type{o})];
                        end
                        rec(r).work.remObs(id);
                    end
                end
            end
        end

        function runNet(this, rec, tok)
            % Execute Network undifferenced solution
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runPPP(rec, tok)
%             if true
%                 rec.netPrePro();
%             end
            [id_trg, found] = this.getMatchingRec(rec, tok, 'T');
%             if true
%                 rec(id_trg).netPrePro();
%             end
            if ~found
                this.log.addWarning('No target found -> nothing to do');
            else
                [sys_list, sys_found] = this.getConstellation(tok);
                [id_ref, found_ref] = this.getMatchingRec(rec, tok, 'R');
                if ~found_ref
                    id_ref = id_trg; % Use all the receiver as mean reference
                end
                [id_ref] = intersect(id_trg, id_ref);
                if isempty(id_ref)
                    this.log.addWarning('No reference have been found, using the mean of the receiver for the computation');
                end
                net = this.core.getNetwork(id_trg, rec);
                net.reset();
                iono_reduce = false;
                coo_rate = [];
                [rate, found] = this.getNumericPar(tok, this.PAR_RATE.par);
                if found
                    coo_rate = rate;
                end
                for t = 1 : numel(tok)
                    if ~isempty(regexp(tok{t}, ['^(' this.PAR_IONO.par ')*$'], 'once'))
                       iono_reduce = true;
                    end
                end
                %try
                    net.adjust(id_ref, coo_rate, iono_reduce); 
                %catch ex
                %    this.log.addError(['Command_Interpreter - Network solution failed: ' ex.message]);
                %end
                for t = 1 : numel(tok)
                    if ~isempty(regexp(tok{t}, ['^(' this.PAR_E_COO_CRD.par ')*$'], 'once'))
                        net.exportCrd();
                    end
                end
            end
            %fh = figure; plot(zero2nan(rec(2).work.sat.res)); fh.Name = 'Res'; dockAllFigures;
        end

        function runCodePP(this, rec, tok)
            % Execute Code Point Positioning
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runCodePP(rec, tok)            
            [id_trg, found] = this.getMatchingRec(rec, tok, 'T');
            if ~found
                this.log.addWarning('No target found -> nothing to do');
            else
                [sys_list, sys_found] = this.getConstellation(tok);
                [id_ref, found_ref] = this.getMatchingRec(rec, tok, 'R');
                for r = id_trg
                    this.log.newLine();
                    this.log.addMarkedMessage(sprintf('Code positioning on receiver %d: %s', id_trg, rec(r).getMarkerName()));
                    this.log.smallSeparator();
                    this.log.newLine();
                    if sys_found
                        rec(r).work.initPositioning(sys_list);
                    else
                        rec(r).work.initPositioning();
                    end
                end
            end
        end
        
        function runSEID(this, rec, tok)
            % Synthesise L2 observations on a target receiver given a set of dual frequency reference stations
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runSEID(rec, tok)
            [id_trg, found_trg] = this.getMatchingRec(rec, tok, 'T');
            if ~found_trg
                this.log.addWarning('No target found => nothing to do');
            else
                [id_ref, found_ref] = this.getMatchingRec(rec, tok, 'R');
                if ~found_ref
                    this.log.addWarning('No reference SEID station found -> nothing to do');
                else
                    tic; Core_SEID.getSyntL2(rec.getWork(id_ref), rec.getWork(id_trg)); toc;
                end
            end
        end
        
        function runRemIono(this, rec, tok)
            % Remove iono model from observations on a target receiver given a set of dual frequency reference stations
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runSEID(rec, tok)
            [id_trg, found_trg] = this.getMatchingRec(rec, tok, 'T');
            if ~found_trg
                this.log.addWarning('No target found => nothing to do');
            else
                [id_ref, found_ref] = this.getMatchingRec(rec, tok, 'R');
                if ~found_ref
                    this.log.addWarning('No reference SEID station found -> nothing to do');
                else
                    tic; Core_SEID.remIono(rec.getWork(id_ref), rec.getWork(id_trg)); toc;
                end
            end
        end
        
        function runKeep(this, rec, tok)
            % Filter Receiver data
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runKeep(rec, tok)
            [id_trg, found_trg] = this.getMatchingRec(rec, tok, 'T');
            if ~found_trg
                this.log.addWarning('No target found -> nothing to do');
            else
                [rate, found] = this.getNumericPar(tok, this.PAR_RATE.par);
                if found
                    for r = id_trg
                        this.log.addMarkedMessage(sprintf('Keeping a rate of %ds for receiver %d: %s', rate, r, rec(r).parent.getMarkerName()));
                        if rec(r).isEmpty
                            rec(r).load();
                        end
                        rec(r).keep(rate);
                    end
                end
                [snr_thr, found] = this.getNumericPar(tok, this.PAR_SNRTHR.par);
                if found
                    for r = id_trg
                        % this.log.addMarkedMessage(sprintf('Keeping obs with SNR (L1) above %d dbHZ for receiver %d: %s', snr_thr, r, rec(r).getMarkerName()));
                        if rec(r).isEmpty
                            rec(r).load();
                        end
                        rec(r).remUnderSnrThr(snr_thr);
                    end
                end
                [cut_off, found] = this.getNumericPar(tok, this.PAR_CUTOFF.par);
                if found
                    for r = id_trg
                        % this.log.addMarkedMessage(sprintf('Keeping obs with elevation above %.1f for receiver %d: %s', cut_off, r, rec(r).getMarkerName()));
                        if rec(r).isEmpty
                            rec(r).load();
                        end
                        rec(r).remUnderCutOff(cut_off);
                    end
                end
                [sys_list, found] = this.getConstellation(tok);
                if found
                    for r = id_trg
                        this.log.addMarkedMessage(sprintf('Keeping constellations "%s" for receiver %d: %s', sys_list, r, rec(r).parent.getMarkerName()));
                        if rec(r).isEmpty
                            rec(r).load();
                        end
                        rec(r).keep([], sys_list);
                    end
                end
            end
        end
        
        function runOutDet(this, rec, tok)
            % Perform outlier rejection and cycle slip detection
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runOutDet(rec)
            [id_trg, found_trg] = this.getMatchingRec(rec, tok, 'T');
            if ~found_trg
                this.log.addWarning('No target found -> nothing to do');
            else
                for r = id_trg
                    this.log.addMarkedMessage(sprintf('Outlier rejection and cycle slip detection for receiver %d: %s', r, rec(r).getMarkerName()));
                    rec(r).work.updateDetectOutlierMarkCycleSlip();
                end
            end
        end
        
        function runSync(this, rec, tok)
            % Filter Receiver data
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runKeep(rec, tok)
            [~, found_trg] = this.getMatchingRec(rec, tok, 'T');
            if ~found_trg
                this.log.addWarning('No target found -> nothing to do');
            else
                [rate, found] = this.getRate(tok);
                if found
                    Receiver.sync(rec, rate);
                else
                    Receiver.sync(rec);
                end
            end
        end
        
        function runShow(this, rec, tok, sss_lev)
            % Show Images
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runShow(rec, tok, level)
            if nargin < 3 || isempty(sss_lev)
                sss_lev = 0;
            end
            [id_trg, found_trg] = this.getMatchingRec(rec, tok, 'T');
            if ~found_trg
                this.log.addWarning('No target found -> nothing to do');
            else
                for t = 1 : numel(tok) % gloabal for all target
                    try
                        if sss_lev == 0
                            trg = rec(id_trg);
                        else
                            trg = [rec(id_trg).work];
                        end
                        if ~isempty(regexp(tok{t}, ['^(' this.PAR_S_MAP.par ')*$'], 'once'))
                            trg.showMap();
                        elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_PTH.par ')*$'], 'once'))
                            rec(id_trg).showPTH();
                        elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_ZTD.par ')*$'], 'once'))
                            trg.showZtd();
                        elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_ZWD.par ')*$'], 'once'))
                            trg.showZwd();
                        elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_PWV.par ')*$'], 'once'))
                            trg.showPwv();
                        elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_STD.par ')*$'], 'once'))
                            trg.showZtdSlant();
                        elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_ENUBSL.par ')*$'], 'once'))
                            trg.showBaselineENU();
                        end
                        
                    catch ex
                        this.log.addError(sprintf('%s',ex.message));
                    end
                end
                
                for r = id_trg % different for each target
                    for t = 1 : numel(tok)
                        try
                            if sss_lev == 0
                                trg = rec(r);
                            else
                                trg = [rec(r).work];
                            end
                            
                            if ~isempty(regexp(tok{t}, ['^(' this.PAR_S_ALL.par ')*$'], 'once'))
                                trg.showAll();
                            elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_DA.par ')*$'], 'once'))
                                trg.showDataAvailability();
                            elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_ENU.par ')*$'], 'once'))
                                trg.showPositionENU();
                            elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_XYZ.par ')*$'], 'once'))
                                trg.showPositionXYZ();
                            elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_CK.par ')*$'], 'once'))
                                trg.showDt();
                            elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_SNR.par ')*$'], 'once'))
                                trg.showSNR_p();
                            elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_OCS.par ')*$'], 'once'))
                                trg.showOutliersAndCycleSlip();
                            elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_OCSP.par ')*$'], 'once'))
                                trg.showOutliersAndCycleSlip_p();
                            elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_RES.par ')*$'], 'once'))
                                trg.showRes();
                            elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_RES_SKY.par ')*$'], 'once'))
                                trg.showResSky_c();
                            elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_RES_SKYP.par ')*$'], 'once'))
                                trg.showResSky_p();
                            elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_S_RES_STD.par ')*$'], 'once'))
                                trg.showZtdSlantRes_p();
                            end
                        catch ex
                            this.log.addError(sprintf('Receiver %s: %s', trg.getMarkerName, ex.message));
                        end
                    end
                end
            end
        end
        
        function runExport(this, rec, tok, sss_lev)
            % Export results
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   this.runExport(rec, tok, level)
            if nargin < 3 || isempty(sss_lev)
                sss_lev = 0;
            end

            [id_trg, found_trg] = this.getMatchingRec(rec, tok, 'T');
            if ~found_trg
                this.log.addWarning('No target found -> nothing to do');
            else                
                for r = id_trg % different for each target
                    this.log.newLine();
                    this.log.addMarkedMessage(sprintf('Exporting receiver %d: %s', r, rec(r).getMarkerName()));
                    this.log.smallSeparator();
                    this.log.newLine();
                    for t = 1 : numel(tok)
                        try
                            if ~isempty(regexp(tok{t}, ['^(' this.PAR_E_REC_RIN.par ')*$'], 'once'))
                                rec(r).work.exportRinex3();
                            else
                                if sss_lev == 0 % run on all thw results (out)
                                    if ~isempty(regexp(tok{t}, ['^(' this.PAR_E_TROPO_SNX.par ')*'], 'once'))
                                        pars       = regexp(tok{t},'(?<=[\(,])[0-9a-zA-Z]*','match'); %match everything that is follows a parenthesis or a coma
                                        export_par = false(length(this.PAR_E_TROPO_SNX.accepted_values),1);
                                        if isempty(pars)
                                            export_par([1,2,3]) = true; % by defaul export only ztd and gradients
                                        elseif strcmpi(pars{1},'ALL')
                                            export_par(:) = true; % export all
                                        else
                                            for i = 1 : length(pars)
                                                for j = 1 : length(export_par)
                                                    if strcmpi(pars{i}, this.PAR_E_TROPO_SNX.accepted_values{j})
                                                        export_par(j) = true;
                                                    end
                                                end
                                            end
                                        end
                                        rec(r).out.exportTropoSINEX(export_par);
                                    elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_E_TROPO_MAT.par ')*$'], 'once'))
                                        rec(r).out.exportTropoMat();
                                    elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_E_REC_MAT.par ')*$'], 'once'))
                                        rec(r).exportMat();
                                    end
                                else % run in single session mode (work)
                                    if ~isempty(regexp(tok{t}, ['^(' this.PAR_E_TROPO_SNX.par ')*$'], 'once'))
                                        rec(r).work.exportTropoSINEX();
                                    elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_E_TROPO_MAT.par ')*$'], 'once'))
                                        rec(r).work.exportTropoMat();
                                    elseif ~isempty(regexp(tok{t}, ['^(' this.PAR_E_REC_MAT.par ')*$'], 'once'))
                                        rec(r).work.exportMat();
                                    end
                                end
                            end
                        catch ex
                            this.log.addError(sprintf('Receiver %s: %s', rec(r).getMarkerName, ex.message));
                        end
                    end
                end
            end
        end
    end
    %
    %% METHODS UTILITIES (PRIVATE)
    % ==================================================================================================================================================
    methods (Access = public)       
        function [id_rec, found, matching_rec] = getMatchingRec(this, rec, tok, type)
            % Extract from a set of tokens the receivers to be used
            %
            % INPUT
            %   rec     list of rec objects
            %   tok     list of tokens(parameters) from command line (cell array)
            %   type    type of receavers to search for ('T'/'R'/'M') 
            %
            % SYNTAX
            %   [id_rec, found, matching_rec] = this.getMatchingRec(rec, tok, type)
            if nargin == 2
                type = 'T';
            end
            [id_rec, found] = getMatchingKey(this, tok, type, numel(rec));
        end
        
        function [id_sss, found] = getMatchingSession(this, tok)
            % Extract from a set of tokens the session to be used
            %
            % INPUT
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   [id_sss, found] = this.getMatchingSession(tok)            
                    state = Core.getCurrentSettings(); 
                    n_key = state.getSessionCount();
                    [id_sss, found] = getMatchingKey(this, tok, 'S', n_key);
        end
        
        function [id_trg, found] = getMatchingTarget(this, tok)
            % Extract from a set of tokens the target to be used
            %
            % INPUT
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   [id_sss, found] = this.getMatchingSession(tok)            
            [id_trg, found] = getMatchingKey(this, tok, 'T', 10000); % 10000 maximum number of targets
        end
        
        function [id_key, found] = getMatchingKey(this, tok, type, n_key)
            % Extract from a set of tokens the ids to be used
            %
            % INPUT
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   [id_sss, found] = this.getMatchingKey(tok)            
            
            id_key = [];
            found = false;
            t = 0;
            
            while ~found && t < numel(tok)
                t = t + 1;
                % Search receiver identified after the key character "type"
                if ~isempty(tok{t}) && tok{t}(1) == type
                    % Analyse all the receiver identified on the string
                    % e.g. T*        all the receivers
                    %      T1,3:5    receiver 1,3,4,5
                    str_rec = tok{t}(2:end);
                    take_all = ~isempty(regexp(str_rec,'[\*]*', 'once'));
                    if take_all
                        id_key = 1 : n_key;
                    else
                        [ids, pos_ids] = regexp(str_rec,'[0-9]*', 'match');
                        ids = str2double(ids);
                        
                        % find *:*:*
                        [sequence, pos_sss] = regexp(str_rec,'[0-9]*:[0-9]*:[0-9]*', 'match');
                        
                        for s = 1 : numel(sequence)
                            pos_par = regexp(sequence{s},'[0-9]*');
                            id_before = find(pos_ids(:) == (pos_sss(s) + pos_par(1) - 1), 1, 'last');
                            %id_step = find(pos_ids(:) == (pos_sss(s) + pos_par(2) - 1), 1, 'first');                            
                            %id_after = find(pos_ids(:) == (pos_sss(s) + pos_par(3) - 1), 1, 'first');
                            id_step = id_before + 1; 
                            id_after = id_before + 2; 
                            if ~isempty(id_before)
                                id_key = [id_key ids(id_before) : ids(id_step) : ids(id_after)]; %#ok<AGROW>
                                ids(id_before : id_after) = [];
                                pos_ids(id_before : id_after) = [];
                            end                            
                        end
                        
                        % find *:*                                                
                        pos_colon = regexp(str_rec,':*');
                        for p = 1 : numel(pos_colon)
                            id_before = find(pos_ids(:) < pos_colon(p), 1, 'last');
                            id_after = find(pos_ids(:) > pos_colon(p), 1, 'first');
                            if ~isempty(id_before) && ~isempty(id_after)
                                id_key = [id_key ids(id_before) : ids(id_after)]; %#ok<AGROW>
                            end
                        end
                        id_key = unique([ids id_key]);
                        id_key(id_key > n_key) = [];
                    end
                    found = ~isempty(id_key);
                end
            end
            if isempty(id_key) % as default return all the sessions
                id_key = 1 : n_key;
            end
        end    
        
        function [num, found] = getNumericPar(this, tok, par_regexp)
            % Extract from a set of tokens a number for a certain parameter
            %
            % INPUT
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   [num, found] = this.getNumericPar(tok, this.PAR_RATE.par)
            found = false;            
            num = str2double(regexp([tok{:}], ['(?<=' par_regexp ')[+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)*'], 'match', 'once'));
            if ~isempty(num) && ~isnan(num)
                found = true;
            end
        end
        
        function [sys, found] = getConstellation(this, tok)
            % Extract from a set of tokens the constellation parameter
            %
            % INPUT
            %   tok     list of tokens(parameters) from command line (cell array)
            %
            % SYNTAX
            %   [sys, found] = this.getConstellation(tok)
            found = false;            
            sys = regexp([tok{:}], ['(?<=' this.PAR_SS.par ')[GREJCIS]*'], 'match', 'once');
            if ~isempty(sys)
                found = true;
            end
        end
        
        function [cmd, err, id] = getCommandValidity(this, str_cmd)
            % Extract from a string the goGPS command found
            %
            % INPUT
            %   str_cmd     command as a string
            %
            % OUTPUT
            %   cmd         command struct for the found command
            %   err         error number (==0 ok) (> 0 on error) (< 0 on warning)
            %    id         internal usage id in the VALID_CMD array
            %
            % SYNTAX
            %  [cmd, err, id] = getCommandValidity(this, str_cmd)
            err = 0;
            tok = regexp(str_cmd,'[^ ]*', 'match');
            cmd = [];
            id = [];
            if isempty(tok)
                err = this.WRN_MPT; % no command found
            else
                str_cmd = tok{1};
                id = this.CMD_ID((strcmp(str_cmd, this.VALID_CMD)));
                if isempty(id)
                    err = this.ERR_UNK; % command unknown
                else
                    if id > numel(this.CMD_LIST)
                        cmd = this.(sprintf('KEY_%s', this.KEY_LIST{id - numel(this.CMD_LIST)}));
                    else
                        cmd = this.(sprintf('CMD_%s', this.CMD_LIST{id}));
                    end
                    if ~isfield(cmd, 'key')
                        cmd.key = '';
                    end
                    if numel(tok) < (1 + numel(cmd.rec))
                        err = this.ERR_NEI; % not enough input parameters
                    elseif numel(tok) > (1 + numel(cmd.rec) + numel(cmd.par) + numel(cmd.key))
                        err = this.WRN_TMI; % too many input parameters
                    end
                end
            end
        end
    end
    %
    %% METHODS UTILITIES
    % ==================================================================================================================================================
    methods
        function [cmd_list, err_list, execution_block, sss_list, trg_list, key_lev, flag_push] = fastCheck(this, cmd_list)
            % Check a cmd list keeping the valid commands only
            %
            % INPUT
            %   cmd_list    command as a cell array
            %
            % OUTPUT
            %   cmd_list    list with all the valid commands
            %   err         error list
            %
            % SYNTAX
            %  [cmd, err_list, execution_block, sss_list, trg_list, key_lev] = fastCheck(this, cmd_list)
            if nargout > 3
                state = Core.getCurrentSettings();
            end
            % remove empty lines
            for c = length(cmd_list) : -1 : 1
                if isempty(cmd_list{c})
                    cmd_list(c) = [];
                end
                    
            end
            err_list = zeros(size(cmd_list));   
            sss = 1;
            trg = [];
            lev = 0;
            sss_id_counter = 0;
            par_id_counter = 0;
            execution_block = zeros(1, numel(cmd_list));
            flag_push = false(0,0);
            sss_list = cell(numel(cmd_list), 1);
            trg_list = cell(numel(cmd_list), 1);
            key_lev = zeros(1, numel(cmd_list));
            for c = 1 : numel(cmd_list)
                [cmd, err_list(c)] = this.getCommandValidity(cmd_list{c});
                if (nargout > 2)
                    if err_list(c) == 0 && (cmd.id == this.KEY_FOR.id)
                        % I need to loop
                        sss_id_counter = sss_id_counter + 1;
                        lev = lev + 1;
                        tok = regexp(cmd_list{c},'[^ ]*', 'match'); % get command tokens
                        sss = this.getMatchingSession(tok);
                    end
                    if err_list(c) == 0 && (cmd.id == this.KEY_PAR.id)
                        % I need to loop
                        par_id_counter = par_id_counter + 1;
                        lev = lev + 1;
                        tok = regexp(cmd_list{c},'[^ ]*', 'match'); % get command tokens
                        trg = this.getMatchingTarget(tok);
                    end
                    if err_list(c) == 0 && (cmd.id == this.KEY_ENDPAR.id)
                        % I need to loop
                        par_id_counter = par_id_counter + 1;
                        lev = lev - 1;
                        trg = [];
                    end
                    if err_list(c) == 0 && (cmd.id == this.KEY_ENDFOR.id)
                        % I need to loop
                        sss_id_counter = sss_id_counter + 1;
                        lev = lev - 1;
                        sss = sss(end);
                    end
                end
                
                if err_list(c) > 0
                    this.log.addError(sprintf('%s - cmd %03d "%s"', this.STR_ERR{abs(err_list(c))}, c, cmd_list{c}));
                end
                if err_list(c) < 0 && err_list(c) > -100
                    this.log.addWarning(sprintf('%s - cmd %03d "%s"', this.STR_ERR{abs(err_list(c))}, c, cmd_list{c}));
                end
                execution_block(c) = sss_id_counter;
                if ~isempty(cmd)
                    flag_push_command = any(cell2mat(strfind(this.PUSH_LIST, cmd.name{1})));
                else
                    flag_push_command = false;
                end
                if length(flag_push) < (sss_id_counter+1)
                    flag_push(sss_id_counter+1) = false;
                end
                flag_push(sss_id_counter+1) = flag_push(sss_id_counter+1) || flag_push_command;
                key_lev(c) = lev;
                sss_list{c} = sss;
                trg_list{c} = trg;
            end   
           
            cmd_list = cmd_list(~err_list);
            execution_block = execution_block(~err_list);
            sss_list = sss_list(~err_list);
            key_lev = key_lev(~err_list);
            if nargout > 3 && sss_id_counter == 0 % no FOR found
                for s = 1 : numel(sss_list)
                    sss_list{s} = 1 : state.getSessionCount();
                end
            end
        end                
    end    
end
