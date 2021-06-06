#!/usr/bin/env python
from ROOT import TCanvas, TFile, TLegend, gStyle, gPad


gStyle.SetOptStat(0)
gStyle.SetErrorX(0)
gStyle.SetFrameLineWidth(1)
gStyle.SetTitleSize(0.045, "x")
gStyle.SetTitleSize(0.045, "y")
gStyle.SetMarkerSize(1)
gStyle.SetLabelOffset(0.015, "x")
gStyle.SetLabelOffset(0.02, "y")
gStyle.SetTickLength(-0.02, "x")
gStyle.SetTickLength(-0.02, "y")
gStyle.SetTitleOffset(1.1, "x")
gStyle.SetTitleOffset(1.0, "y")

def saveCanvas(canvas, title):
    format_list = ["png", ".pdf", ".root"]
    for fileFormat in format_list:
        canvas.SaveAs(title + fileFormat)

def kinematic_plots(var1):
    fileo2 = TFile("combine_sig.root")
    cres = TCanvas("cres", "resolution distribution")
    cres.SetCanvasSize(1500, 700)
    cres.Divide(2,1)    
    sig = fileo2.Get("hf-task-jpsi-mc/h%sSig" % var1)
    bkg = fileo2.Get("hf-task-jpsi-mc/h%sBg" % var1)
    cres.cd(1)
    gPad.SetLogz()
    sig.Draw("coltz")
    sig.SetTitle("%s Signal distribution(Rec. Level)" % var1)
    cres.cd(2)
    gPad.SetLogz()
    bkg.Draw("coltz")
    bkg.SetTitle("%s Background distribution(Rec. Level)" % var1)
    saveCanvas(cres, "%s" % var1)



var_list = ["Chi2PCA", "Ct", "Y", "d0Prong0", "d0Prong1", "d0d0", "declength", "declengthxy", "mass"]

for var in var_list:
    kinematic_plots(var)


