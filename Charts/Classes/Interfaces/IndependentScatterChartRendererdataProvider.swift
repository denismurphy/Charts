//
//  IndependentScatterChartRendererdataProvider.swift
//  Charts
//
//  Created by Gerard J. Cerchio on 5/12/16.
//  Copyright © 2016 dcg. All rights reserved.
//

import Foundation
import CoreGraphics

@objc
public protocol IndependentScatterChartRendererdataProvider: BarLineScatterCandleBubbleChartDataProvider
{
    var scatterData: IndependentScatterChartData? { get }
}