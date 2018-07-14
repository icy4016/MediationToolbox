function mediation_brain_results_report(varargin)
%
% This function runs and saves tables, images, and clusters
% for a, b, and ab effects of a two-level mediation model
% 
% - Run from mediation results directory
%
% - Preliminary version: This is "version 1" and does not have the full functionality of 
% mediation_brain_results_all_script, but is complementary. 
%
% - Saves region objects with extracted data within each region
% - Requires object oriented tools in CANlab_Core_Tools
% - Used in publish_mediation_brain_results_report to create published reports.
%
% The thresholds are fixed right now, and two sets of results are run:
% One at .01, and one with an across-contrast FDR correction at q < .05
%
% See also: mediation_brain_results_all_script.m
%           publish_mediation_brain_results_report.m

% Default options - could be changed later
% --------------------------------------------------------

whmontage = 5;  % which montage to put name on
kthresh = 3;    % cluster extent threshold
pthresh = .01;  % P-value threshold for uncorrected results



% Display helper functions: Called by later scripts
% --------------------------------------------------------

dashes = '----------------------------------------------';
%printstr = @(dashes) disp(dashes);
printhdr = @(str) fprintf('%s\n%s\n%s\n', dashes, str, dashes);


%% Loading results and mask
% ----------------------------------------------------------------

printhdr('LOADING mediation results and images');

[SETUP, mask_obj, a_obj, b_obj, ab_obj, data_obj] = load_mediation_results_objects; % and run FDR if needed

printhdr('Loaded mediation:');
disp(SETUP)


% Initialize fmridisplay if needed and show mask
% --------------------------------------------------------------------
[o2, fig_number] = setup_slice_display([], 1);
o2 = addblobs(o2, region(mask_obj), 'trans');

drawnow, snapnow


%% FDR-corrected results
% ----------------------------------------------------------------
[o2, fig_number] = setup_slice_display([], 3);

printhdr('FDR-corrected results');
disp('Results corrected across set of a, b, ab images using mediation_brain_corrected_threshold');
fprintf('FDR q < .05 = p < %3.8f\n', SETUP.fdr_p_thresh);

printhdr('Path a, FDR-corrected q < .05')

a_obj = threshold(a_obj, SETUP.fdr_p_thresh, 'unc', 'k', kthresh);
o2 = addblobs(o2, region(a_obj), 'wh_montages', 1:2);
axes(o2.montage{2}.axis_handles(whmontage))
title('Path a');

a_regions_fdr = region(a_obj, data_obj);      % Create regions; extract average data in each region into obj.dat
table(a_regions_fdr);                             % Print table
fprintf('\n\n');

printhdr('Path b, FDR-corrected q < .05')

b_obj = threshold(b_obj, SETUP.fdr_p_thresh, 'unc', 'k', kthresh);
o2 = addblobs(o2, region(b_obj), 'wh_montages', 3:4);
axes(o2.montage{4}.axis_handles(whmontage))
title('Path b');

b_regions_fdr = region(b_obj, data_obj);      % Create regions; extract average data in each region into obj.dat
table(b_regions_fdr);                             % Print table
fprintf('\n\n');

printhdr('Path ab, FDR-corrected q < .05')

ab_obj = threshold(ab_obj, SETUP.fdr_p_thresh, 'unc', 'k', kthresh);
o2 = addblobs(o2, region(ab_obj), 'wh_montages', 5:6);
axes(o2.montage{6}.axis_handles(whmontage))
title('Path ab');

ab_regions_fdr = region(ab_obj, data_obj);      % Create regions; extract average data in each region into obj.dat
table(ab_regions_fdr);                             % Print table
fprintf('\n\n');

drawnow, snapnow  % flush figure to report


%% Uncorrected results
% ----------------------------------------------------------------
[o2, fig_number] = setup_slice_display([], 3);

printhdr('Uncorrected (p < .01)  results');

printhdr('Path a, Uncorrected (p < .01)')

a_obj = threshold(a_obj, pthresh, 'unc', 'k', kthresh);
o2 = addblobs(o2, region(a_obj), 'wh_montages', 1:2);
axes(o2.montage{2}.axis_handles(whmontage))
title('Path a');

a_regions_01unc = region(a_obj, data_obj);      % Create regions; extract average data in each region into obj.dat
table(a_regions_01unc);                             % Print table
fprintf('\n\n');

printhdr('Path b, Uncorrected (p < .01)')

b_obj = threshold(b_obj, pthresh, 'unc', 'k', kthresh);
o2 = addblobs(o2, region(b_obj), 'wh_montages', 3:4);
axes(o2.montage{4}.axis_handles(whmontage))
title('Path b');

b_regions_01unc = region(b_obj, data_obj);      % Create regions; extract average data in each region into obj.dat
table(b_regions_01unc);                             % Print table
fprintf('\n\n');

printhdr('Path ab, Uncorrected (p < .01)')

ab_obj = threshold(ab_obj, pthresh, 'unc', 'k', kthresh);
o2 = addblobs(o2, region(ab_obj), 'wh_montages', 5:6);
axes(o2.montage{6}.axis_handles(whmontage))
title('Path ab');

ab_regions_01unc = region(ab_obj, data_obj);      % Create regions; extract average data in each region into obj.dat
table(ab_regions_01unc);                             % Print table
fprintf('\n\n');

drawnow, snapnow  % flush figure to report



% Save
% ---------------------------------------------------------------------

printhdr('Saving extracted objects to disk.');
disp('a_obj, b_obj, ab_obj : statistic_image objects for paths a, b, ab');
disp('a_regions_fdr, etc.  : region objects for paths a, b, ab at FDR threshold');
disp('a_regions_unc, etc.  : region objects for paths a, b, ab at uncorrected threshold');
disp('In region objects, region_obj(i).dat contains extracted data for the i-th significant region, averaged over voxels');
disp('Use these data in plots, secondary analyses, or to re-run mediation.m within individual regions');

savefilename = fullfile(pwd, 'Statistic_image_and_region_objects.mat');

save(savefilename, 'a_*', 'b_*', 'ab_*'); 

fprintf('\n\n');
    
end % main function






% Sub-functions
% ---------------------------------------------------------------------


function [SETUP, mask_obj, a_obj, b_obj, ab_obj, data_obj] = load_mediation_results_objects

% Load SETUP
% ----------------------------------------------------------------
if ~exist(fullfile(pwd, 'mediation_SETUP.mat'), 'file')
    error('Cannot find mediation_SETUP.mat in current directory. Please go to a valid mediation directory.');
else
    load(fullfile(pwd, 'mediation_SETUP.mat'))
end

% FDR correction across images
% ----------------------------------------------------------------
if ~isfield(SETUP, 'fdr_p_thresh')
    SETUP = mediation_brain_corrected_threshold('fdr');
end

% single or multi-level dir?
% ----------------------------------------------------------------
if exist(fullfile(pwd, 'mask.img'), 'file') && isfield(SETUP, 'data') && iscell(SETUP.data.X)  % multilevel mediation dirs have this image
    
    ismultilevel = 1;
    disp('Using mask.img stored in current directory (automatically written for mediation analyses) for mask.');
    mask = fullfile(pwd, 'mask.img');
    
elseif isfield(SETUP, 'data') && iscell(SETUP.data.X)
    warning('Multilevel mediation: mask.img is missing');
else
    % SETUP.X, Y Z instead of SETUP.data
    ismultilevel = 0;
    % single-level mask stored here
    mask = SETUP.mask;
    
end

if ~exist(mask, 'file')
    disp('Mask cannot be found/is not a valid file.  Using gray_matter_mask.img in CANlab core.');
    
    mask = which('gray_matter_mask.img');
    
end

% Load objects
% --------------------------------------------------------------------

mask_obj = fmri_data(mask, 'noverbose');

a_obj = create_stat_object('X-M_effect.img', 'X-M_pvals.img');
b_obj = create_stat_object('M-Y_effect.img', 'M-Y_pvals.img');
ab_obj = create_stat_object('X-M-Y_effect.img', 'X-M-Y_pvals.img');

data_obj = load_image_data_object(SETUP);

end



function data_obj = load_image_data_object(SETUP)

image_names = SETUP.M;
if ~ischar(image_names), image_names = SETUP.X; end
if ~ischar(image_names), image_names = SETUP.Y; end
if ~ischar(image_names), disp('Cannot find image names'); end

image_names = check_valid_imagename(image_names);

if isempty(image_names)
    data_obj = [];
else
    data_obj = fmri_data(image_names, [], 'noverbose');
end

end


function [o2, fig_number] = setup_slice_display(o2, num_rows)

whmontage = 5;

% Check conditions:
fmridisplay_is_ok = true;
if ~exist('o2', 'var') || ~isa(o2, 'fmridisplay')
    fmridisplay_is_ok = false;
    
elseif length(o2.montage) < whmontage
    % wrong fmridisplay object for this plot
    fmridisplay_is_ok = false;
    
elseif ~all(ishandle(o2.montage{whmontage}.axis_handles))
    % Figure was closed or axes deleted
    fmridisplay_is_ok = false;
    
end

if ~fmridisplay_is_ok
    
    create_figure('fmridisplay'); axis off
    o2 = canlab_results_fmridisplay([], 'multirow', num_rows, 'noverbose');
    
else % Ok, reactivate, clear blobs, and clear name
    
    o2 = removeblobs(o2);
    axes(o2.montage{whmontage}.axis_handles(5));
    title(' ');
end

% Get figure number - to reactivate figure later, even if we are changing its tag
hh = get(o2.montage{1}.axis_handles, 'Parent');  %findobj('Tag', 'fmridisplay');
if iscell(hh), hh = hh{1}; end
fig_number = hh(1).Number;

end




function pstat = create_stat_object(effectimgname, pimgname)

% a_obj = create_stat_object('X-M_effect.img', 'X-M_pvals.img');
% b_obj = create_stat_object('M-Y_effect.img', 'M-Y_pvals.img');
% ab_obj = create_stat_object('X-M-Y_effect.img', 'X-M-Y_pvals.img');

pstat = statistic_image(pimgname, 'type', 'p');

mstat = fmri_data(effectimgname, [], 'noverbose');

% add effects/sign
pstat.dat = mstat.dat;

end


