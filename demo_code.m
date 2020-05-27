hdr = double(hdrread('memorial.hdr'));
ldr = tmo_histpq(hdr);
figure, imshow(uint8(255*ldr));


