//
//  IndependentScatterChartRenderer.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 4/3/15.
//  derived from ScatterChart by Gerard J. Cerchio
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif

//@objc
//public protocol IndependentScatterChartRendererdataProvider
//{
//    func scatterChartRendererData(renderer: IndependentScatterChartRenderer) -> IndependentScatterChartData!
//    func scatterChartRenderer(renderer: IndependentScatterChartRenderer, transformerForAxis which: ChartYAxis.AxisDependency) -> ChartTransformer!
//    func scatterChartDefaultRendererValueFormatter(renderer: IndependentScatterChartRenderer) -> NSNumberFormatter!
//    func scatterChartRendererChartYMax(renderer: IndependentScatterChartRenderer) -> Double
//    func scatterChartRendererChartYMin(renderer: IndependentScatterChartRenderer) -> Double
//    func scatterChartRendererChartXMax(renderer: IndependentScatterChartRenderer) -> Double
//    func scatterChartRendererChartXMin(renderer: IndependentScatterChartRenderer) -> Double
//    func scatterChartRendererMaxVisibleValueCount(renderer: IndependentScatterChartRenderer) -> Int
//}

public class IndependentScatterChartRenderer: LineScatterCandleRadarChartRenderer
{
    public weak var dataProvider: IndependentScatterChartRendererdataProvider?
    
    public init(dataProvider: IndependentScatterChartRendererdataProvider?, animator: ChartAnimator?, viewPortHandler: ChartViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        self.dataProvider = dataProvider
    }
    
    public override func drawData(context context: CGContext?)
    {
        guard let scatterData = dataProvider?.scatterData else { return }
        
        for i in 0 ..< scatterData.dataSetCount
        {
            let set = scatterData.getDataSetByIndex(i)
            
            if ( (set !== nil && set!.isVisible) && ( ( set.yMax != 0 ) && ( set.yMax != 0 ) ) )
            {
                drawDataSet(context: context, dataSet: set as! IndependentScatterChartDataSet)
            }
        }
    }
    
    private var _lineSegments = [CGPoint](count: 2, repeatedValue: CGPoint())
    
    internal func drawDataSet(context context: CGContext?, dataSet: IndependentScatterChartDataSet)
    {
        guard let
            dataProvider = dataProvider,
            animator = animator
            else { return }
        
        let trans = dataProvider.getTransformer(dataSet.axisDependency)
        
        let phaseY = animator.phaseY
        
        var entries = dataSet.yVals
        let entryCount = dataSet.entryCount
        
        let shapeSize = dataSet.scatterShapeSize
        let shapeHalf = shapeSize / 2.0
        
        var point = CGPoint()
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        let shape = dataSet.scatterShape
        
        CGContextSaveGState(context)
        
        for j in 0 ..< Int(min(ceil(CGFloat(entryCount) * animator.phaseX), CGFloat(entryCount)))
        {
            let e = entries[j];
            point.x = CGFloat(e.xIndex);
            point.y = CGFloat(e.value) * phaseY;
            point = CGPointApplyAffineTransform(point, valueToPixelMatrix);
            
            if (!viewPortHandler.isInBoundsLeft(point.x) || !viewPortHandler.isInBoundsY(point.y))
            {
                continue
            }
            
            if (shape == .Square)
            {
                CGContextSetFillColorWithColor(context, dataSet.colorAt(j).CGColor)
                var rect = CGRect()
                rect.origin.x = point.x - shapeHalf
                rect.origin.y = point.y - shapeHalf
                rect.size.width = shapeSize
                rect.size.height = shapeSize
                CGContextFillRect(context, rect)
            }
            else if (shape == .Circle)
            {
                CGContextSetFillColorWithColor(context, dataSet.colorAt(j).CGColor)
                var rect = CGRect()
                rect.origin.x = point.x - shapeHalf
                rect.origin.y = point.y - shapeHalf
                rect.size.width = shapeSize
                rect.size.height = shapeSize
                CGContextFillEllipseInRect(context, rect)
            }
            else if (shape == .Cross)
            {
                CGContextSetStrokeColorWithColor(context, dataSet.colorAt(j).CGColor)
                _lineSegments[0].x = point.x - shapeHalf
                _lineSegments[0].y = point.y
                _lineSegments[1].x = point.x + shapeHalf
                _lineSegments[1].y = point.y
                CGContextStrokeLineSegments(context, _lineSegments, 2)
                
                _lineSegments[0].x = point.x
                _lineSegments[0].y = point.y - shapeHalf
                _lineSegments[1].x = point.x
                _lineSegments[1].y = point.y + shapeHalf
                CGContextStrokeLineSegments(context, _lineSegments, 2)
            }
            else if (shape == .Triangle)
            {
                CGContextSetFillColorWithColor(context, dataSet.colorAt(j).CGColor)
                
                // create a triangle path
                CGContextBeginPath(context)
                CGContextMoveToPoint(context, point.x, point.y - shapeHalf)
                CGContextAddLineToPoint(context, point.x + shapeHalf, point.y + shapeHalf)
                CGContextAddLineToPoint(context, point.x - shapeHalf, point.y + shapeHalf)
                CGContextClosePath(context)
                
                CGContextFillPath(context)
            }
            else if (shape == .Custom)
            {
                CGContextSetFillColorWithColor(context, dataSet.colorAt(j).CGColor)
                
                let customShape = dataSet.customScatterShape
                
                if (customShape === nil)
                {
                    return
                }
                
                // transform the provided custom path
                CGContextSaveGState(context)
                CGContextTranslateCTM(context, -point.x, -point.y)
                
                CGContextBeginPath(context)
                CGContextAddPath(context, customShape)
                CGContextFillPath(context)
                
                CGContextRestoreGState(context)
            }
        }
        
        CGContextRestoreGState(context)
    }
    
    public override func drawValues(context context: CGContext?)
    {
        guard let
            dataProvider = dataProvider,
            scatterData = dataProvider.scatterData,
            animator = animator
            else { return }
        
        var lastPoint = CGPoint();
        var lastIndex = 0;
        var lastInBounds = false;
        
        // if values are drawn
        if (scatterData.yValCount < Int(ceil(CGFloat(dataProvider.maxVisibleValueCount) * viewPortHandler.scaleX)))
        {
            guard let dataSets = scatterData.dataSets as? [IndependentScatterChartDataSet] else { return }
            
            for i in 0 ..< scatterData.dataSetCount
            {
                let dataSet = dataSets[i]
                let phaseX = max(0.0, min(1.0, animator.phaseX))
                let phaseY = animator.phaseY
                
                if ( !dataSet.isDrawValuesEnabled || ( ( dataSet.yMax == 0 ) && ( dataSet.yMin == 0 ) ) )
                {
                    continue
                }
                
                let valueFont = dataSet.valueFont
                let valueTextColor = dataSet.valueTextColor
                guard let formatter = dataSet.valueFormatter else { continue }
                
                let trans = dataProvider.getTransformer(dataSet.axisDependency)
                let valueToPixelMatrix = trans.valueToPixelMatrix
                var entries = dataSet.yVals
                var pt = CGPoint()
                let entryCount = dataSet.entryCount
                
                let shapeSize = dataSet.scatterShapeSize;
                let lineHeight = valueFont.lineHeight;
                let lineYoffset = shapeSize + lineHeight;
                
                if ( dataSet.drawLinesEnabled )
                {
                    CGContextSaveGState(context);
                    CGContextClipToRect( context, viewPortHandler.contentRect );
                }

                for j in 0 ..< Int(ceil(CGFloat(entryCount) * phaseX))
                {
                    guard let e = dataSet.entryForIndex(j) else { break }
                    pt.x = CGFloat(e.xIndex)
                    pt.y = CGFloat(e.value) * phaseY
                    pt = CGPointApplyAffineTransform(pt, valueToPixelMatrix)
                    
                    let inBounds = !((!viewPortHandler.isInBoundsLeft(pt.x) || !viewPortHandler.isInBoundsY(pt.y)));
                    
                    var val = (Double)(j);
                    let point = CGPoint(x: pt.x, y: pt.y - shapeSize - lineHeight);
                    
                    if ( !dataSet.valueIsIndex )
                    {
                        val = entries[j].value;
                    }
                    
                    if ( inBounds )
                    {
                        let text = formatter.stringFromNumber(val);
                        
                        ChartUtils.drawText(context: context!,
                                            text: text!,
                                            point: point,
                                            align: .Center,
                                            attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: valueTextColor]);
                    }
                    
                    if (  dataSet.drawLinesEnabled && inBounds &&
                          ( j != 0 ) && ( j == lastIndex + 1 ) )
                    {
                        CGContextSetStrokeColorWithColor(context, dataSet.colorAt(i).CGColor);
                        CGContextMoveToPoint( context, lastPoint.x, lastPoint.y + lineYoffset );
                        CGContextAddLineToPoint( context, point.x, point.y + lineYoffset );
                        
                        lastPoint = point;
                        lastIndex = j;
                        lastInBounds = inBounds;
                    }
                    else
                    {
                        if ( lastInBounds && ( j == lastIndex + 1 ) )
                        {
                            CGContextSetStrokeColorWithColor(context, dataSet.colorAt(i).CGColor);
                            CGContextMoveToPoint( context, lastPoint.x, lastPoint.y + lineYoffset );
                            CGContextAddLineToPoint( context, point.x, point.y + lineYoffset );
                        }
                        lastPoint = point;
                        lastIndex = j;
                        lastInBounds = inBounds;
                    }
                }
                
                if ( dataSet.drawLinesEnabled )
                {
                    CGContextStrokePath( context );
                    CGContextRestoreGState(context);
                }
            }
            
        }
    }
    
   
    public override func drawExtras(context context: CGContext? )
    {
        
    }
    private var _highlightPointBuffer = CGPoint()
    
    public override func drawHighlighted(context context: CGContext, indices: [ChartHighlight])
    {
        guard let
            dataProvider = dataProvider,
            scatterData = dataProvider.scatterData,
            animator = animator
            else { return }
        
        let chartXMax = dataProvider.chartXMax
        
        CGContextSaveGState(context)
        
        for high in indices
        {
            let minDataSetIndex = high.dataSetIndex == -1 ? 0 : high.dataSetIndex
            let maxDataSetIndex = high.dataSetIndex == -1 ? scatterData.dataSetCount : (high.dataSetIndex + 1)
            if maxDataSetIndex - minDataSetIndex < 1 { continue }
            
            for dataSetIndex in minDataSetIndex..<maxDataSetIndex
            {
                guard let set = scatterData.getDataSetByIndex(dataSetIndex) as? IScatterChartDataSet else { continue }
                
                if !set.isHighlightEnabled
                {
                    continue
                }
                
                CGContextSetStrokeColorWithColor(context, set.highlightColor.CGColor)
                CGContextSetLineWidth(context, set.highlightLineWidth)
                if (set.highlightLineDashLengths != nil)
                {
                    CGContextSetLineDash(context, set.highlightLineDashPhase, set.highlightLineDashLengths!, set.highlightLineDashLengths!.count)
                }
                else
                {
                    CGContextSetLineDash(context, 0.0, nil, 0)
                }
                
                let xIndex = high.xIndex; // get the x-position
                
                if (CGFloat(xIndex) > CGFloat(chartXMax) * animator.phaseX)
                {
                    continue
                }
                
                let yVal = set.yValForXIndex(xIndex)
                if (yVal.isNaN)
                {
                    continue
                }
                
                let y = CGFloat(yVal) * animator.phaseY; // get the y-position
                
                _highlightPointBuffer.x = CGFloat(xIndex)
                _highlightPointBuffer.y = y
                
                let trans = dataProvider.getTransformer(set.axisDependency)
                
                trans.pointValueToPixel(&_highlightPointBuffer)
                
                // draw the lines
                drawHighlightLines(context: context, point: _highlightPointBuffer, set: set)
            }
        }
        
        CGContextRestoreGState(context)
    }
}
