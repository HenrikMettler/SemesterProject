function [data] = spatFilter(data, type, numChannels,lap)
if type == 'CAR'
    mean_data = mean(data(1:numChannels,:),1);
    for ch = 1:1:numChannels
        data(ch,:) = data(ch,:)-mean_data;
    end
elseif type == 'LAP'
    data = lap*data(1:numChannels,:);
else
    error('This spatial filter type is not valid. Allowed options are: "CAR", "LAP"');
end

end
