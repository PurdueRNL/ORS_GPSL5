#!/usr/bin/env python2
# -*- coding: utf-8 -*-
##################################################
# GNU Radio Python Flow Graph
# Title: Top Block
# Generated: Mon May  9 12:33:48 2016
##################################################

if __name__ == '__main__':
    import ctypes
    import sys
    if sys.platform.startswith('linux'):
        try:
            x11 = ctypes.cdll.LoadLibrary('libX11.so')
            x11.XInitThreads()
        except:
            print "Warning: failed to XInitThreads()"

from gnuradio import eng_notation
from gnuradio import gr
from gnuradio import uhd
from gnuradio import wxgui
from gnuradio.eng_option import eng_option
from gnuradio.fft import window
from gnuradio.filter import firdes
from gnuradio.wxgui import fftsink2
from gnuradio.wxgui import forms
from grc_gnuradio import wxgui as grc_wxgui
from optparse import OptionParser
import time
import wx


class top_block(grc_wxgui.top_block_gui):

    def __init__(self):
        grc_wxgui.top_block_gui.__init__(self, title="Top Block")
        _icon_path = "/usr/share/icons/hicolor/32x32/apps/gnuradio-grc.png"
        self.SetIcon(wx.Icon(_icon_path, wx.BITMAP_TYPE_ANY))

        ##################################################
        # Variables
        ##################################################
        self.samp_rate = samp_rate = 4.2e6
        self.gain = gain = 40
        self.freq = freq = 1575420000
        self.bandw = bandw = samp_rate
        self.AveAlpha = AveAlpha = 0.0043

        ##################################################
        # Blocks
        ##################################################
        _gain_sizer = wx.BoxSizer(wx.VERTICAL)
        self._gain_text_box = forms.text_box(
        	parent=self.GetWin(),
        	sizer=_gain_sizer,
        	value=self.gain,
        	callback=self.set_gain,
        	label='gain',
        	converter=forms.float_converter(),
        	proportion=0,
        )
        self._gain_slider = forms.slider(
        	parent=self.GetWin(),
        	sizer=_gain_sizer,
        	value=self.gain,
        	callback=self.set_gain,
        	minimum=0,
        	maximum=100,
        	num_steps=1000,
        	style=wx.SL_HORIZONTAL,
        	cast=float,
        	proportion=1,
        )
        self.Add(_gain_sizer)
        _freq_sizer = wx.BoxSizer(wx.VERTICAL)
        self._freq_text_box = forms.text_box(
        	parent=self.GetWin(),
        	sizer=_freq_sizer,
        	value=self.freq,
        	callback=self.set_freq,
        	label='freq',
        	converter=forms.float_converter(),
        	proportion=0,
        )
        self._freq_slider = forms.slider(
        	parent=self.GetWin(),
        	sizer=_freq_sizer,
        	value=self.freq,
        	callback=self.set_freq,
        	minimum=1,
        	maximum=10000000000000,
        	num_steps=1000,
        	style=wx.SL_HORIZONTAL,
        	cast=float,
        	proportion=1,
        )
        self.Add(_freq_sizer)
        _AveAlpha_sizer = wx.BoxSizer(wx.VERTICAL)
        self._AveAlpha_text_box = forms.text_box(
        	parent=self.GetWin(),
        	sizer=_AveAlpha_sizer,
        	value=self.AveAlpha,
        	callback=self.set_AveAlpha,
        	label='AveAlpha',
        	converter=forms.float_converter(),
        	proportion=0,
        )
        self._AveAlpha_slider = forms.slider(
        	parent=self.GetWin(),
        	sizer=_AveAlpha_sizer,
        	value=self.AveAlpha,
        	callback=self.set_AveAlpha,
        	minimum=0.001,
        	maximum=0.05,
        	num_steps=1000,
        	style=wx.SL_HORIZONTAL,
        	cast=float,
        	proportion=1,
        )
        self.Add(_AveAlpha_sizer)
        self.wxgui_fftsink2_0 = fftsink2.fft_sink_c(
        	self.GetWin(),
        	baseband_freq=freq,
        	y_per_div=1,
        	y_divs=10,
        	ref_level=-80,
        	ref_scale=2.0,
        	sample_rate=samp_rate,
        	fft_size=1024,
        	fft_rate=15,
        	average=True,
        	avg_alpha=AveAlpha,
        	title="FFT Plot",
        	peak_hold=False,
        	win=window.rectangular,
        )
        self.Add(self.wxgui_fftsink2_0.win)
        self.uhd_usrp_source_0_0 = uhd.usrp_source(
        	",".join(("", "type=usrp2,addr=192.168.10.2")),
        	uhd.stream_args(
        		cpu_format="fc32",
        		channels=range(1),
        	),
        )
        self.uhd_usrp_source_0_0.set_clock_rate(samp_rate*2, uhd.ALL_MBOARDS)
        self.uhd_usrp_source_0_0.set_samp_rate(samp_rate)
        self.uhd_usrp_source_0_0.set_center_freq(freq, 0)
        self.uhd_usrp_source_0_0.set_gain(gain, 0)
        self.uhd_usrp_source_0_0.set_antenna("RX2", 0)
        self.uhd_usrp_source_0_0.set_bandwidth(bandw, 0)

        ##################################################
        # Connections
        ##################################################
        self.connect((self.uhd_usrp_source_0_0, 0), (self.wxgui_fftsink2_0, 0))    

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.set_bandw(self.samp_rate)
        self.uhd_usrp_source_0_0.set_samp_rate(self.samp_rate)
        self.wxgui_fftsink2_0.set_sample_rate(self.samp_rate)

    def get_gain(self):
        return self.gain

    def set_gain(self, gain):
        self.gain = gain
        self._gain_slider.set_value(self.gain)
        self._gain_text_box.set_value(self.gain)
        self.uhd_usrp_source_0_0.set_gain(self.gain, 0)
        	
        self.uhd_usrp_source_0_0.set_gain(self.gain, 1)
        	

    def get_freq(self):
        return self.freq

    def set_freq(self, freq):
        self.freq = freq
        self._freq_slider.set_value(self.freq)
        self._freq_text_box.set_value(self.freq)
        self.uhd_usrp_source_0_0.set_center_freq(self.freq, 0)
        self.uhd_usrp_source_0_0.set_center_freq(self.freq, 1)
        self.wxgui_fftsink2_0.set_baseband_freq(self.freq)

    def get_bandw(self):
        return self.bandw

    def set_bandw(self, bandw):
        self.bandw = bandw
        self.uhd_usrp_source_0_0.set_bandwidth(self.bandw, 0)
        self.uhd_usrp_source_0_0.set_bandwidth(self.bandw, 1)

    def get_AveAlpha(self):
        return self.AveAlpha

    def set_AveAlpha(self, AveAlpha):
        self.AveAlpha = AveAlpha
        self._AveAlpha_slider.set_value(self.AveAlpha)
        self._AveAlpha_text_box.set_value(self.AveAlpha)


def main(top_block_cls=top_block, options=None):

    tb = top_block_cls()
    tb.Start(True)
    tb.Wait()


if __name__ == '__main__':
    main()
