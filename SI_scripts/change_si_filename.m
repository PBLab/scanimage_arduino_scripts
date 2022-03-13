% Update ScanImage's filename
%
% This script adds metadata to the filename in a structured way, so that
% the experimenter won't have to enter these parameters manually each time.
% The currently added parameters are the experiment type ('exptype'), mouse
% ID, day, FOV and condition. The script also automatically adds the
% magnification, pixels per line and framerate, as well as whether the
% scanning was bi- or unidirectional. Any extra metadata can be manually
% added in the 'extras' field, as per the example.
%
% If you wish to leave one of the fields empty enter a value of ''.

filename = struct();

% Enter parameters below:
filename.exptype = 'left_hemi';
filename.mouse = 'm19';
filename.day = '0';
filename.fov = 3;
filename.condition = '512px';
% We record the magnification, pixelization and framerate automatically
filename.mag = num2str(hSI.hRoiManager.scanZoomFactor);
filename.px = num2str(hSI.hRoiManager.pixelsPerLine);
filename.Hz = num2str(int16(hSI.hRoiManager.scanFrameRate));
% If you wish to add any other metadata, do so in the 'extras' field, in
% the following manner:
% filename.extras = {'right_hemisphere', 'no_run_data'};
filename.extras = {'z'}; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Do not change below %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

full_fname = string('');

fn = fieldnames(filename);
% Iterate over all fields besides the 'extras' one, which will receive
% special treatment shortly thereafter
for num = 1:(numel(fn) - 1)
    value = filename.(fn{num});
    if strcmp(value, '')
        continue
    end
    addition = ...
        string(fn{num}) + ...
        string('_') + ...
        string(value) + ...
        string('_');
    full_fname = full_fname + addition;
end

% Deal with extra fields
for extra = filename.extras
   addition = string(extra) + string('_');
   full_fname = full_fname + addition;
end

% Bidirectional \ unidirectional
if hSI.hScan2D.bidirectional
    full_fname = full_fname + string('bidir_');
else
    full_fname = full_fname + string('unidir_');
end
    
% Final cleanups
full_fname = full_fname + string('000') + string(hSI.hScan2D.logFileCounter);
full_fname = char(full_fname);
hSI.hScan2D.logFileStem = full_fname;
