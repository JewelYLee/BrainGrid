function showDiff(x,y,z)
i = size(z);
i = i(1)
for k = 1:i
   x(z(k,1),z(k,2)) - y(z(k,1),z(k,2))
end