function set_dark_mode(h2fig)
%set a 'dark mode' for the figure specified in h2fig'

%% parameters
background_color = [.2 .2 .2];
axis_color = [.7 .7 .7];
%%
set(h2fig,'color',background_color)
fig_axes = findobj(h2fig,'type','axes');
set(fig_axes,'color',background_color,'xcolor',axis_color,'ycolor',axis_color)