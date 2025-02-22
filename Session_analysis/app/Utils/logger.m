function logger(app,frmt_str,varargin)
%logger function writes to log tab or screen depending on user call.

if nargin>2
    val = varargin{1};
else
    val = [];
end

%determine call mode
switch class(app)
    case 'Session_analyzer'
        call_mode = 'gui';
    otherwise
        call_mode = 'standalone';
end


new_str = [datestr(now) ': ' sprintf(frmt_str,val)];
if strcmp(call_mode,'gui')
    log_str = app.ExecutionlogTextArea.Value;
    log_str = [log_str;{new_str}];
    app.ExecutionlogTextArea.Value = log_str;
else
    fprintf('\n%s',new_str);
end
