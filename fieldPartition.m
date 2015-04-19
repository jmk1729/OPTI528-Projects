function Fields = fieldPartition(field,K,usenew)
if nargin == 2
    usenew = false;
end
            n = size(field,2); %number of pixels in the x direction (row number)
            m = size(field,1); %column number (y direction)
            K = K; %lenslet number for a square grid (K by K)
            %% nxn Matrix breakup into KxK lenslet array
            a = field;
            b = cell(K,K); %lenslet fields
            %Easy cases
            if n == 1
                b = a;
                fprintf('You should know this outcome! b = %f \n',b);
            elseif n/K == 1
                for k = 1:K
                    for l = 1:K
                        b{k,l} = a(k,l);
                    end
                end
            else
                %Three and higher
                if mod(n,K) == 0
                    spacing = round((n/K) - 1);
                else
                    spacing = floor((n-1)/K);
                end
                starty = 1;
                endy = starty + spacing;
                for i = 1:K
                    startx = 1;
                    endx = startx + spacing;
                    for j = 1:K
                        b{i,j} = a(starty:endy,startx:endx);
                        if mod(n,K) == 0
                            startx = startx + spacing + 1;
                            endx = endx + spacing + 1;
                        else
                            startx = startx + spacing;
                            endx = endx + spacing;
                        end
                        if endx > n
                            break;
                        end
                    end
                    if mod(n,K) == 0
                        starty = starty + spacing + 1;
                        endy = endy + spacing + 1;
                    else
                        starty = starty + spacing;
                        endy = endy + spacing;
                    end
                    if endy > m
                        break;
                    end
                end
            end
            
            if usenew == true
                for nn = 1:length(b)
                    for n = 1:length(b)
                        if mod(length(b{nn,n}),2) == 0
                            b{nn,n} = b{nn,n}(1:end-1,1:end-1);
                        end
                    end
                end
            end
            Fields = b;
        end %fieldPartition