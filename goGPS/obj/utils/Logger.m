%   SINGLETON CLASS Logger
% =========================================================================
%
% DESCRIPTION
%   Manage messages output depending on the current interface
%   (up to now, only Command Windows is implemented)
%
% EXAMPLE
%   log = Logger.getInstance();
%
% FOR A LIST OF CONSTANTs and METHODS use doc Logger

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

classdef Logger < handle

    properties (Constant, GetAccess = public)
        DEFAULT_VERBOSITY_LEV   = 9;  % Default verbosity level
        WARNING_VERBOSITY_LEV   = 3;  % Warning verbosity level
        ERROR_VERBOSITY_LEV     = 1;  % Error verbosity level
        
        STD_OUT        = 1;     % Output: text only   (first bit set)
        STD_FILE       = 2;     % Output: file only   (second bit set)    
        STD_OUT_N_FILE = 3;     % Output: file + text (first and second bit set)
        
        ORANGE = [1 0.65 0];
    end

    properties (GetAccess = 'private', SetAccess = 'protected')
        color_mode = true;                        % Flag for coloured output messages (if true requires cprintf)
        verbosity = Logger.DEFAULT_VERBOSITY_LEV; % Verbosity level
        std_out = Logger.STD_OUT;                 % Define the standard output of the logger
        
        out_file_path                             % Path to the logging file
        file_out_mode = 'w+';                     % log to file in (w/a) mode (w+ = new file, a+ = append)
        fid                                       % File handler
    end

    methods (Access = private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function this = Logger()
            % Initialisation of the variables
            if isdeployed
                this.color_mode = false;
            end
            if isunix
                if ismac % is Mac
                    this.out_file_path = '~/Library/Logs/goGPS/go_gps ${NOW}.log';
                else     % is Linux
                    this.out_file_path = './logs/go_gps ${NOW}.log';
                end
            elseif ispc  % is Windows
                this.out_file_path = './logs/go_gps ${NOW}.log';
            end
        end
    end

    methods (Static)
        function this = getInstance()
            % Concrete implementation.  See Singleton superclass.
            persistent unique_instance_logger__
            if isempty(unique_instance_logger__)
                this = Logger();
                unique_instance_logger__ = this;
            else
                this = unique_instance_logger__;
            end
        end
    end

    % =========================================================================
    %  MANAGING LOGGING
    % =========================================================================
    methods
        % Out status ------------------------------------------------------
        
        function is_active = isScreenOut(this)
            % Show log on screen
            %
            % SYNTAX
            %   is_active = isScreenOut(this)
            
            % get first bit
            is_active = bitand(this.std_out, 1, 'uint8') > 0;
        end

        function is_active = isFileOut(this)
            % Save log on file
            %
            % SYNTAX
            %   is_active = isFileOut(this)
            
            % get second bit
            is_active =  bitand(this.std_out, 2, 'uint8') > 0;
        end
        
        function disableFileOut(this)
            % Disable logging on file
            %
            % SYNTAX
            %   log.disableFileOut()
            
            this.setOutMode([], false);            
        end
        
        function enableFileOut(this)
            % Enable logging on file
            %
            % SYNTAX
            %   log.enableFileOut()
            
            this.setOutMode([], true);
        end
        
        function setOutMode(this, screen_out, file_out)
            % Enable and disable various output mode
            % Inputs are boolean or empty
            %
            % SYNTAX
            %   this.setOutMode(<screen_out>, <file_out>)
            %
            
            if ~isempty(screen_out)
                % set first bit
                if screen_out
                    this.std_out = bitor(this.std_out, 1, 'uint8');
                else
                    this.std_out = bitxor(this.std_out, 1, 'uint8');
                end
            end
            
            if (nargin > 2) && ~isempty(file_out)
                % set second bit
                if file_out
                    this.std_out = bitor(this.std_out, 2, 'uint8');
                else
                    this.std_out = bitxor(this.std_out, 2, 'uint8');
                end
            end
        end
        
        % Set read status mode --------------------------------------------
        function setColorMode(this, bool)
            % Set useage of colors in text output
            this.color_mode = bool;
        end

        function bool = getColorMode(this)
            % Get useage of colors in text output
            bool = this.color_mode;
        end

        % Set verbosity level ---------------------------------------------
        function setVerbosityLev(this, verbosity)
            % Set level of verbosity
            this.verbosity = verbosity;
        end

        function verbosity = getVerbosityLev(this)
            % Get level of verbosity
            verbosity = this.verbosity;
        end
                    
        function [std_out, file_out_mode] = getOutMode(this)
            % Get output mode
            std_out = this.std_out;
            file_out_mode = this.file_out_mode;
        end
        
        % Set file of log  ------------------------------------------------
        function setOutFile(this, out_file_path, file_out_mode)
            % Set the output logging file path
            %
            % INPUT:
            %   file_out_mode  'w'     open file for writing; discard existing contents (DEFAULT)
            %                  'a'     open or create file for writing; append data to end of file
            %
            % SYNTAX:
            %   log.setOutFile(<out_file_path>, <file_out_mode>)
            %
            % NOTES
            %   ${NOW} when present in the name is substituted with the current date_time yyyymmdd HH:MM:SS
            if this.isFileOut % File                
                if nargin < 3 || isempty(file_out_mode)
                    file_out_mode = this.file_out_mode;
                end
                
                if nargin < 2 || isempty(out_file_path)
                    % Set default name
                    if isunix
                        if ismac % is Mac
                            this.out_file_path = '~/Library/Logs/goGPS/go_gps_${NOW}.log';
                        else     % is Linux
                            this.out_file_path = './logs/go_gps_${NOW}.log';
                        end
                    elseif ispc  % is Windows
                        this.out_file_path = './logs/go_gps_${NOW}.log';
                    end
                    
                    out_file_path = this.out_file_path;
                end
                
                % Test out file path
                [f_dir, ~, ~] = fileparts(out_file_path);
                if ~isempty(f_dir) && ~(exist(f_dir, 'file') == 7) % if it is not an existing folder
                    mkdir(f_dir); % create the missing folder
                end
                
                try fclose(this.fid); catch; end % if is not open do nothing
                
                out_file_path = strrep(out_file_path, '${NOW}', datestr(now, 'yyyymmdd_HHMMSS'));
                this.fid = fopen(out_file_path, file_out_mode);
                if this.fid <= 0
                    this.fid = 0;
                    error('Unable to open logging at %s', out_file_path);
                else
                    this.out_file_path = out_file_path;
                end
            end
        end
        
        function closeFile(this)
            % Close the log file
            %
            % SYNTAX
            %   log.closeFile()
            
                try fclose(this.fid); catch; end % if is not open do nothing            
        end
        
        function out_file_path = getFilePath(this)
            % Get the file path of the output file
            %
            % SYNTAX:
            %   out_file_path = log.getFilePath();
            
            out_file_path = this.out_file_path;
        end

        function fid = getOutFId(this)
            % Get the handler of the output file
            try
                resp = ftell(this.fid); % Test if the file is open    
                if resp == -1
                     throw(MException('FileNotOpen', 'The log file is not open'));
                end
            catch % file is not open => try to create it or open it
                out_file_path = this.out_file_path;
                [f_dir, ~, ~] = fileparts(out_file_path);
                if ~isempty(f_dir) && ~(exist(f_dir, 'file') == 7) % if it is not an existing folder
                    mkdir(f_dir); % create the missing folder
                end
                
                try fclose(this.fid); catch; end % if is not open do nothing
                               
                out_file_path = strrep(out_file_path, '${NOW}', datestr(now, 'yyyymmdd HHMMSS'));
                this.fid = fopen(out_file_path, 'a+');
                if this.fid <= 0
                    this.fid = 0;
                    error('Unable to open logging at %s\n', out_file_path);
                else
                    this.out_file_path = out_file_path;
                end
            end
            if this.fid <= 0
                this.fid = 0;
                error('Unable to open logging at %s', this.out_file_path);
            end
            fid = this.fid;            
        end

    end

    % =========================================================================
    %  OUTPUT UTILITIES (respect verbosity)
    % =========================================================================
    methods
        function newLine(this, verbosity_level)
            % Send a message through the standard interface
            if (nargin < 2)
                verbosity_level = this.DEFAULT_VERBOSITY_LEV;
            end
            if (verbosity_level <= this.verbosity)
                if this.isScreenOut % Screen
                    fprintf('\n');
                end
                if this.isFileOut % File
                    fprintf(this.getOutFId, '\n');
                end
            end
        end

        function simpleSeparator(this, verbosity_level, color)
            % Send a message through the standard interface
            if (nargin < 2) || isempty(verbosity_level)
                verbosity_level = this.DEFAULT_VERBOSITY_LEV;
            end
            if (verbosity_level <= this.verbosity)
                if this.isScreenOut % Screen
                    if this.color_mode && ~(nargin < 3 || isempty(color))
                        cprintf(color, '----------------------------------------------------------------------------');
                        cprintf('text', '\n');
                    else
                        fprintf('--------------------------------------------------------------------------\n');
                    end
                end
                if this.isFileOut % File
                    fprintf(this.getOutFId, '------------------------------------------------------------------------\n');
                end
                
            end
        end
        
        function starSeparator(this, verbosity_level, color)
            % Send a message through the standard interface
            if (nargin < 2) || isempty(verbosity_level)
                verbosity_level = this.DEFAULT_VERBOSITY_LEV;
            end            
            
            if (verbosity_level <= this.verbosity)
                if this.isScreenOut % Screen
                    if this.color_mode && ~(nargin < 3 || isempty(color))
                        cprintf(color, '  **********************************************************************');
                        cprintf('text', '\n');
                    else
                        fprintf('  **********************************************************************\n');
                    end
                end
                if this.isFileOut % File
                    fprintf(this.getOutFId, '  **********************************************************************\n');
                end
            end
        end
                
        function smallSeparator(this, verbosity_level)
            % Send a message through the standard interface
            if (nargin < 2)
                verbosity_level = this.DEFAULT_VERBOSITY_LEV;
            end
            if (verbosity_level <= this.verbosity)
                if this.isScreenOut % Screen
                    fprintf('  --------------------------------------------------------------------\n');
                end
                if this.isFileOut % File
                    fprintf(this.getOutFId, '  --------------------------------------------------------------------\n');
                end
            end
        end
        
        function addMarkedMessage(this, text, verbosity_level)
            % Send a message through the standard interface
            if (nargin < 3)
                verbosity_level = this.DEFAULT_VERBOSITY_LEV;
            end
            text = strrep(text, char(10), char([10, 32 * ones(1,7)]));
            text = strrep(text, '\n', char([10, 32 * ones(1,7)]));
            if (verbosity_level <= this.verbosity)
                if this.isScreenOut % Screen
                    if this.color_mode
                        text = strrep(text, '\', '\\');
                        cprintf('Green','   **   ');
                        cprintf('text', strcat(text, '\n'));
                    else
                        fprintf('   **   %s\n', text);
                    end
                end
                if this.isFileOut % File
                    fprintf(this.getOutFId, '   **   %s\n', text);
                end
            end
        end

        function addMessageToFile(this, text_in, verbosity_level)
            % Send a message through the standard interface
            if (nargin < 3)
                verbosity_level = this.DEFAULT_VERBOSITY_LEV;
            end
            if (verbosity_level <= this.verbosity)
                if iscell(text_in)
                    text = [];
                    for l = 1 : numel(text_in)
                        text = [text text_in{l} char([10, 32])]; %#ok<AGROW>
                    end
                else
                    text = text_in;
                end
                text = strrep(text, char(10), char([10, 32]));
                text = strrep(text, '\n', char([10, 32]));
                if this.isFileOut % File
                    fprintf(this.getOutFId, ' %s\n', text);
                end
            end
        end
        
        function addMessage(this, text, verbosity_level)
            % Send a message through the standard interface
            if (nargin < 3)
                verbosity_level = this.DEFAULT_VERBOSITY_LEV;
            end
            if (verbosity_level <= this.verbosity)
                text = strrep(text, char(10), char([10, 32]));
                text = strrep(text, '\n', char([10, 32]));
                if this.isScreenOut % Screen
                    fprintf(' %s\n', text);
                end
                if this.isFileOut % File
                    fprintf(this.getOutFId, ' %s\n', text);
                end                
            end
        end

        function addStatusOk(this, text, verbosity_level)
            % Send a message through the standard interface
            if (nargin < 3)
                verbosity_level = this.DEFAULT_VERBOSITY_LEV;
            end
            if (nargin < 2)
                text = '';
            end
            if (verbosity_level <= this.verbosity)
                this.printStatusOk(text);
            end
        end

        function addStatusDisabled(this, text, verbosity_level)
            % Send a message through the standard interface
            if (nargin < 3)
                verbosity_level = this.DEFAULT_VERBOSITY_LEV;
            end
            if (nargin < 2)
                text = '';
            end
            if (verbosity_level <= this.verbosity)
                this.printStatusDisabled(text);
            end
        end
        
        function addWarning(this, text, verbosity_level)
            % Send a warning through the standard interface
            if (nargin < 3)
                verbosity_level = this.WARNING_VERBOSITY_LEV;
            end
            if (verbosity_level <= this.verbosity)
                this.printWarning(text);
            end
        end

        function addError(this, text, verbosity_level)
            % Send an error through the standard interface
            if (nargin < 3)
                verbosity_level = this.ERROR_VERBOSITY_LEV;
            end
            if (verbosity_level <= this.verbosity)
                this.printError(text);
            end
        end

        function status(this, status)
            % Display a flag of operation status ( -1 Err, 0 Ok, 1 Warning) on the previous line
            fprintf(char(08));
            this.opStatus(status, this.color_mode);
        end
    end


    % =========================================================================
    %    PRIVATE DISPLAY UTILITIES
    % =========================================================================

    methods (Access = 'protected')

        function printStatusOk(this, text, color_mode)
            % Display Warnings
            if (nargin == 2)
                color_mode = this.color_mode;
            end

            if isempty(text)
                fprintf('\b');
            else
                text = strrep(text, char(10), char([10, 32]));
                text = strrep(text, '\n', char([10, 32]));
                text = strrep(text, '\', '\\');
            end

            this.opStatus(0, color_mode);
            
            if this.isScreenOut % Screen
                if (color_mode)
                    cprintf('text', [text '\n']);
                else
                    fprintf([text '\n']);
                end
            end
            if this.isFileOut % File
                fprintf(this.getOutFId, [text '\n']);
            end
        end
        
        function printStatusDisabled(this, text, color_mode)
            % Display Warnings
            if (nargin == 2)
                color_mode = this.color_mode;
            end

            this.opStatus(2, color_mode);

            if isempty(text)
                fprintf('\b');
            else
                text = strrep(text, char(10), char([10, 32]));
                text = strrep(text, '\n', char([10, 32]));
                text = strrep(text, '\', '\\');
            end
            
            if this.isScreenOut % Screen
                if (color_mode)
                    cprintf('text', [text '\n']);
                else
                    fprintf([text '\n']);
                end
            end
            if this.isFileOut % File
                fprintf(this.getOutFId, [text '\n']);
            end
        end

        function printWarning(this, text, color_mode)
            % Display Warnings
            if (nargin == 2)
                color_mode = this.color_mode;
            end
            this.opStatus(1, color_mode);
            text = strrep(text, char(10), char([10, 32 * ones(1,17)]));
            text = strrep(text, '\n', char([10, 32 * ones(1,17)]));
            text = strrep(text, '\', '\\');
            
            if this.isScreenOut % Screen
                if (color_mode)
                    cprintf(Logger.ORANGE, 'Warning: ');
                    cprintf('text', [text '\n']);
                else
                    fprintf(['WARNING: ' text '\n']);
                end
            end
            if this.isFileOut % File
                fprintf(this.getOutFId, ['WARNING: ' text '\n']);
            end                        
        end

        function printError(this, text, color_mode)
            % Display Errors
            if (nargin == 2)
                color_mode = this.color_mode;
            end
            this.opStatus(-1, color_mode);
            text = strrep(text, char(10), char([10, 32 * ones(1,15)]));
            text = strrep(text, '\n', char([10, 32 * ones(1,15)]));
            text = strrep(text, '\', '\\');
            
            if this.isScreenOut % Screen
                if (color_mode)
                    cprintf('err', 'Error: ');
                    cprintf('text', [text '\n']);
                else
                    fprintf(['ERROR: ' text '\n']);
                end
            end
            if this.isFileOut % File
                fprintf(this.getOutFId, ['ERROR: ' text '\n']);
            end
        end

        function opStatus(this, status, color_mode)
            % Display a flag of operation status ( -1 Err, 0 Ok, 1 Warning)
            if (nargin == 1)
                color_mode = true;
            end
            
            
            if this.isScreenOut % Screen
                if color_mode
                    cprintf('blue',' [ ');
                    switch (status)
                        case 0, cprintf('Green','ok');
                        case 1, cprintf(Logger.ORANGE,'WW');
                        case 2, cprintf([0.5 0.5 0.5],'--');
                        otherwise, cprintf('Red','!!');
                    end
                    cprintf('blue',' ] ');
                else
                    fprintf(' [ ');
                    switch (status)
                        case 0, fprintf('ok');
                        case 1, fprintf('WW');
                        case 2, fprintf('--');
                        otherwise, fprintf('!!');
                    end
                    fprintf(' ] ');
                end
            end
            if this.isFileOut % File
                switch (status)
                    case 0, fprintf(this.getOutFId, ' [ ok ] ');
                    case 1, fprintf(this.getOutFId, ' [ WW ] ');
                    case 2, fprintf(this.getOutFId, ' [ -- ] ');
                    otherwise, fprintf(this.getOutFId, ' [ !! ] ');
                end
            end
        end
    end

    % =========================================================================
    %    DISPLAY UTILITIES
    % =========================================================================

    methods(Static, Access = 'public')        
        function str = indent(str, n_spaces)
            % Add n_spaces at the beginning of each line
            % SYNTAX: str = indent(str, n_spaces)
            if nargin < 2
                n_spaces = 7;
            end
            str = strrep([char(ones(1,n_spaces) * 32) str], char(10), char([10 ones(1, n_spaces) * 32]));
        end
    end

end
