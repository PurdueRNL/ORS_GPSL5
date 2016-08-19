function [Correlation] = circcorr(x, y)
    % Calculates the circular correlation of two vectors via FFT
    % X: vector 1
    % Y: vector 2
    % Correlation: Circular correlation between x and y

    % Find number of rows in x
    sampleAmount = size(x, 2);

    % Compute fourier transforms for both inputs
    transX = fft(x);
    transY = fft(y);

    % Elementally multiply transX and the conjugate of transY
    XYProduct = transX .* conj(transY);

    % Conpute the inverse fourier transform of FTXY, shift it to the
    % origin, then divide by the number of samples in x
    Correlation = (fftshift(ifft(XYProduct)) / sampleAmount);
end