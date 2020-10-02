using DelimitedFiles, Random, Statistics
using XGBoost, LIBLINEAR, LIBSVM, FreqTables
using Suppressor


# load data
loc = "http://archive.ics.uci.edu/ml/machine-learning-databases/"
ds  = "breast-cancer-wisconsin/breast-cancer-wisconsin.data"
url = loc * ds
dat = readdlm(download(url), ',')
keep = mapreduce(x->x, &, dat .!= "?", dims=2)
df = convert(Array{Float64,2}, dat[vec(keep), 2:end])
df[:,10] = 1(df[:,10] .== 2.0)

# partion for traing and testing sets
Random.seed!(1)
function partitionTrainTest(dat::Array{Float64,2}, at::Float64 = 0.7)
    n = size(dat)[1]
    idx = shuffle(1:n)
    train_idx = view(idx, 1:floor(Int, at*n))
    test_idx = view(idx, (floor(Int, at*n)+1):n)
    dat[train_idx,:], dat[test_idx,:]
end

# contingency table
function tableResult(pred, actual)
    n = length(pred)
    a = fill("benign", n)
    a[actual.==0.0] .= "malignant"
    p = fill("benign", n)
    p[pred.==0.0] .= "malignant"
    freqtable(a, p)
end


# print results
function classifyCancer(method, at::Float64 = 0.7)
    train, test = partitionTrainTest(df, at)
    train_X, train_Y = train[:,1:end-1], train[:,end]
    test_X, test_Y = test[:,1:end-1], test[:,end]
    res = []
    if method == "XGBoost"
        num_round = 6
        bst = []
        global bst
        @suppress begin
            bst = xgboost(train_X, num_round, label=train_Y, eta=1, max_depth=2,
                      objective = "binary:logistic")
        end;
        xgbPred = 1.0(XGBoost.predict(bst, test_X) .> 0.5)
        res = tableResult(xgbPred, test_Y)
    elseif method == "linearSVM"
        linearSVM = []
        global linearSVM
        @suppress begin
            linearSVM = linear_train(train_Y, train_X', verbose=true);
        end;
        linearPred, decision_values = linear_predict(linearSVM, test_X')
        res = tableResult(linearPred, test_Y)
    elseif method == "kernelSVM"
        kernelSVM = []
        global kernelSVM
        @suppress begin
            kernelSVM = svmtrain(train_X', train_Y);
        end;
        kernelPred, decision_values = svmpredict(kernelSVM, test_X');
        res = tableResult(kernelPred, test_Y)
    end
#    show(stdout, "text/plain", res)
    return(res)
end


function tableAsHtml(ftab)
    print("<table>\n<tr><td><td  style='text-align:center;'>Benign<td  style='text-align:center;'>malignant\n<tr><td  style='text-align:left;'>benign<td  style='text-align:center;'>",ftab[1,1], "<td  style='text-align:center;'>", ftab[1,2],"\n<tr><td  style='text-align:left;'>malignant<td style='text-align:center;'>", ftab[2,1], "<td style='text-align:center;'>", ftab[2,2] , "\n</table>\n")
end

#classifyCancer("XGBoost", 0.5)
#classifyCancer("linearSVM", 0.5)
#ftab = classifyCancer("kernelSVM", 0.5)

