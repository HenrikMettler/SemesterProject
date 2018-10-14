function featureMatrix = makeFeatMat(concatenatedStop)
    helperMatrix = permute(concatenatedStop,[3,4,2,1]);
    featureMatrix = reshape(helperMatrix,[size(helperMatrix,1)*size(helperMatrix,2),size(helperMatrix,3),size(helperMatrix,4)]);
end

