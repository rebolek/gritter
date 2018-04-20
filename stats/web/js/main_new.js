// First, we destructure utils that we will use frequently
const {
  mergeDeep,
  loadFile
} = window.utils

const {
  makeLineGraph,
  makeBarGraph,
  makePieGraph
} = window.graphs

const get = id => document.getElementById(id)

const $checkboxMain = get('checkbox-main')
const $checkbox7Days = get('checkbox-7-days')
const $checkbox30Days = get('checkbox-30-days')

const $roomTitle = get('room-title')
const $lineGraph = get('line-graph')
const $userName = get('user-name')
const $userJoined = get('user-joined')
const $userImage = get('user-image')
const $userTotal = get('user-total')
const $pieGraph = get('pie-graph')
const $roomsGraph = get('rooms-graph')
const $usersGraph = get('users-graph')

const graphData = {
  margin: { top: 20, right: 20, bottom: 30, left: 70 },
  size: { width: 1100, height: 500 }
}

let filesToLoad = [ loadFile('data/csv/room-list.csv'), loadFile('data/csv/user-list.csv') ]

async function main () {
  $checkboxMain.checked = true
  $checkbox7Days.checked = true
  $checkbox30Days.checked = true

  let data = await Promise.all(filesToLoad)

  let rooms = d3.csvParse(data[0]).reduce((o, { name, file }) => {
    o[name] = file
    return o
  }, {})

  let users = d3.csvParse(data[1]).reduce((o, { name, id }) => {
    o[name] = id
    return o
  })

  let getCheckboxSettings = () => ({
    mainLine: $checkboxMain.checked,
    d7Line: $checkbox7Days.checked,
    d30Line: $checkbox30Days.checked
  })

  let lineGraphState = mergeDeep({}, graphData, {
    source: 'data/csv/rooms/5565a1d415522ed4b3e10094.csv',
    settings: getCheckboxSettings()
  })

  let updateLineGraphState = (slice) => {
    lineGraphState = mergeDeep({}, lineGraphState, slice)
    makeLineGraph($lineGraph, lineGraphState)
  }

  let handleToggle = function (event) {
    updateLineGraphState({
      settings: getCheckboxSettings()
    })
  }

  $checkboxMain.addEventListener('click', handleToggle)
  $checkbox7Days.addEventListener('click', handleToggle)
  $checkbox30Days.addEventListener('click', handleToggle)

  const msgCountGraphData = mergeDeep({}, graphData, {
    source: 'data/csv/msg-count.csv',
    active: true,
    mouseOverHandler: (data, d, i) => {
      let name = data[i].name

      d3.select($roomTitle).text(`Activity in room ${name}`)

      updateLineGraphState({
        source: `data/csv/rooms/${rooms[name]}`,
        settings: getCheckboxSettings()
      })
    }
  })

  const top20GraphData = mergeDeep({}, graphData, {
    source: 'data/csv/top20-messages.csv',
    active: false,
    mouseOverHandler: async (data, d, i) => {
      let name = data[i].name
      console.log("three things: data, name, users");
      console.log(data);
      console.log(name);
      console.log(users);
      let file = await fetch(`data/json/users/${users[name]}.json`)
      let idata = await file.json()

      console.log("idata");
      console.log (idata);
      t = idata

      d3.select($userName).text(idata.name)
      d3.select($userJoined).text(idata.first)
      d3.select($userTotal).text(users.name.count)

      let image = d3.select($userImage)
        .attr('src', idata.avatar)
        .attr('width', 128)
        .attr('height', 128)

      makePieGraph($pieGraph, idata.rooms)
    }
  })

  makeBarGraph($roomsGraph, msgCountGraphData)
  makeBarGraph($usersGraph, top20GraphData)
  makeLineGraph($lineGraph, lineGraphState)
}

main()
