function [featureMatrix,featureMatrix3D] = makeFeatMat(psdEstimate)
    %helperMatrix = permute(psdEstimate,[3,4,2,1]);
    featureMatrix3D = reshape(psdEstimate,[size(psdEstimate,1),size(psdEstimate,2),size(psdEstimate,3)*size(psdEstimate,4)]);
    featureMatrix = reshape(featureMatrix3D,[size(featureMatrix3D,1)*size(featureMatrix3D,2),size(featureMatrix3D,3)]);
end

