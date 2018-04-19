window.graphs = (function ({
  loadFile,
  withProp,
  propMap,
  prop,
  compose,
  identity,
  partition
}) {
  let graphs = {}

  graphs.makeBarGraph = async function makeBarGraph (element, {
    margin,
    size,
    source,
    mouseDownHandler,
    mouseOverHandler
  }) {
    // Empty the existing element
    d3.select(element).html("")

    // Calculate width and height
    let width = size.width - margin.left - margin.right
    let height = size.height - margin.top - margin.bottom

    // Create ranges for d3
    let x = d3.scaleBand()
      .range([ 0, width ])
      .padding(0.1)
    let y = d3.scaleLinear()
      .range([ height, 0 ])

    // Create the svg, set it's size, append 'group' element, apply margins
    let svg = d3.select(element).append('svg')
      .attr('width', size.width)
      .attr('height', size.height)
      .append('g')
      .attr('transform', `translate(${margin.left}, ${margin.top})`)

    // Get the data
    let file = await loadFile(source)
    let data = d3.csvParse(file)


    // We prepare the data, casting property `count` to a Number for every entry in `data`.
    data = data.map(withProp('count', Number))

    console.log(data)

    // For every entry in `data`, we extract the property `name`.
    x.domain(data.map(prop('name')))

    // For every entry in `data`, we extract the property `count`.
    y.domain([ 0, d3.max(data, prop('count')) ])

    // Append the rectangles to the bar chart
    svg.selectAll('.bar')
      .data(data)
      .enter()
      .append('rect')
      .attr('class', 'bar')
      .attr('x', propMap('name', x))
      .attr('width', x.bandwidth())
      .attr('y', propMap('count', y))
      .attr('height', propMap('count', v => height - y(v)))
      .on('mouseover', (d, i) => mouseOverHandler(data, d, i))
      .on('mousedown', (d, i) => mouseDownHandler(data, d, i))

    // Append the X axis
    svg.append('g')
      .attr('transform', `translate(0, ${height})`)
      .call(d3.axisBottom(x))

    // Append the Y axis
    svg.append('g')
      .call(d3.axisLeft(y))

    // We done!
  }

  graphs.makeLineGraph = async function makeLineGraph (element, {
    margin,
    size,
    source,
    settings
  }) {
    // Empty the existing element
    d3.select(element).html("")

    // Calculate width and height
    let width = size.width - margin.left - margin.right
    let height = size.height - margin.top - margin.bottom

    // Create parseTime template function
    let parseTime = d3.timeParse('%d-%b-%Y')

    let x = d3.scaleTime().range([ 0, width ])
    let y = d3.scaleLinear().range([ height, 0 ])

    let transformDateProp = propMap('date', x)

    // Define all the lines
    let mainLine = d3.line()
      .x(transformDateProp)
      .y(propMap('value', y))
      .curve(d3.curveLinear)

    let average7Line = d3.line()
      .x(transformDateProp)
      .y(propMap('avg7', y))
      .curve(d3.curveCardinal)

    let average30Line = d3.line()
      .x(transformDateProp)
      .y(propMap('avg30', y))
      .curve(d3.curveBasis)

    // Create the svg, set it's size, append 'group' element, apply margins
    let svg = d3.select(element).append('svg')
      .attr('width', size.width)
      .attr('height', size.height)
      .append('g')
      .attr('transform', `translate(${margin.left}, ${margin.top})`)

    // Get the data
    let file = await loadFile(source)
    let data = d3.csvParse(file)

    // Prepare the data (convert value to Number, parse date as time)
    data = data.map(
      compose(
        withProp('date', parseTime),
        withProp('value', Number)
      )
    )

    // Scale the data
    x.domain(d3.extent(data, prop('date')))
    y.domain([ 0, d3.max(data, prop('value')) ])

    let drawLine = function (stroke, width, line) {
      svg.append('path')
        .data([data])
        .attr('class', 'line')
        .style('stroke', stroke)
        .style('stroke-width', `${width}px`)
        .attr('d', line)
    }

    // Append selected lines
    if (settings.mainLine) {
      drawLine('rgb(170, 196, 158)', 1, mainLine)
    }

    if (settings.d7Line) {
      drawLine('rgb(85, 148, 79)', 2, average7Line)
    }

    if (settings.d30Line) {
      drawLine('rgb(0, 100, 0)', 3, average30Line)
    }

    // Append the X axis
    svg.append('g')
      .attr('transform', `translate(0, ${height})`)
      .call(d3.axisBottom(x))

    // Append the Y axis
    svg.append('g')
      .call(d3.axisLeft(y))
  }


  graphs.makePieGraph = async function makePieGraph (element, data) {
    // Empty the existing element
    d3.select(element).html("")

    let keys = Object.keys(data)
    let values = Object.values(data)

    let total = values.reduce((a, b) => a + b, 0)
    let [ higher, lower ] = partition(values, e => e > total/50)

    let lowerTotal = lower.reduce((a, b) => a + b, 0)

    higher.push(lowerTotal)

    keys[higher.length - 1] = 'other'
    values = higher

    let width = 400
    let height = 400
    let radius = Math.min(width, height) / 2

    let color = d3.scaleOrdinal()
      .range([ '#98abc5', '#8a89a6', '#7b6888' ])

    let arc = d3.arc()
      .outerRadius(radius - 10)
      .innerRadius(0)

      let labelArc = d3.arc()
        .outerRadius(radius - 40)
        .innerRadius(radius - 40)

      let pie = d3.pie()
        .sort(null)
        .value(identity)

      let svg = d3.select(element).append('svg')
        .attr('width', width)
        .attr('height', height)
        .append('g')
        .attr('transform', `translate(${width / 2}, ${height / 2})`)

      let g = svg.selectAll('.arc')
        .data(pie(values))
        .enter()
        .append('g')
        .attr('class', 'arc')

      g.append('path')
        .attr('d', arc)
        .style('fill', propMap('data', color))

      g.append('text')
        .attr('transform', d => `translate(${labelArc.centroid(d)})`)
        .attr('dy', '.35em')
        .text(d => keys[d.index])
  }

  return graphs
})(utils)
