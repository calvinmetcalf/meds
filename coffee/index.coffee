template ={}

template.selectorist=Mustache.compile """
<option value=''>Procedures</option>
{{#rows}}
<option value='{{name}}'>{{name}}</option>
{{/rows}}
"""
template.states=Mustache.compile """
<option value=''>States</option>
{{#rows}}
<option value='{{key}}'>{{key}}</option>
{{/rows}}
"""
template.title=Mustache.compile "<p>{{what}} for <strong>{{key}}</strong></p>"
template.extreams = Mustache.compile  """<strong>{{direction}}:</strong> {{hospital}} in {{city}}, {{state}} at <span class="text-{{highlight}}">${{price}}</span>"""
template.median = Mustache.compile  """<strong>Median:</strong> ${{median}}"""


reset=(clas)->
	$("#medianRow #{clas}").html('')
	$("#lowRow #{clas}").html('')
	$("#highRow #{clas}").html('')
	$("#titleRow #{clas}").html('')
urlBase = 'https://calvin.iriscouch.com/meds/_design/medicare/_view/total'
urlBaseState = 'https://calvin.iriscouch.com/meds/_design/medicare/_view/tstate'
otherBase = 'https://calvin.iriscouch.com/meds/_design/medicare/_view/covered'
otherBaseState = 'https://calvin.iriscouch.com/meds/_design/medicare/_view/cstate'
stateUrl  = 'https://calvin.iriscouch.com/meds/_design/medicare/_view/state'
makeView = (what,nurl,urlState,clas)->
	()->
		reset(clas)
		state = $("#stateSelect").val()
		if state
			url = urlState
		else
			url = nurl
		unless 	$('#totselect').val()
			return true
		key = $('#totselect').val()
		$.ajax(
			url:url
			data:
				startkey:if state then "[\"#{key}\",\"#{state}\"]"  else "[\"#{key}\"]" 
				limit:1
				group_level:if state then 2 else 1
			dataType:"jsonp"
		).then (data)->
			count = parseInt data.rows[0].value.count,10
			skip = Math.ceil(count / 2) - 1
			limit = 2-(count % 2)
			outData={}
			outData.key=key
			outData.what=what
			$("#titleRow #{clas}").html(template.title(outData))
			$.ajax(
				url:url
				data:
					startkey:if state then "[\"#{key}\",\"#{state}\"]" else "[\"#{key}\"]" 
					skip:skip
					limit:limit
					reduce:false
				dataType : "jsonp"
			).then (data)->
				if limit is 2
					outData.median = (0.5*(data.rows[0].value+data.rows[1].value)).toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
				else
					outData.median = data.rows[0].value.toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
				$("#medianRow #{clas}").html(template.median(outData))
		
			$.ajax(
				url:url
				data:
					startkey:if state then "[\"#{key}\",\"#{state}\"]" else "[\"#{key}\"]" 
					limit:1
					reduce:false
				dataType : "jsonp"
			).then (data)->
				if state
					min = {direction:'Cheapest',highlight:'success',state:data.rows[0].key[1],hospital:data.rows[0].key[3],city:data.rows[0].key[4],price:data.rows[0].key[2].toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")}
				else
					min = {direction:'Cheapest',highlight:'success',state:data.rows[0].key[4],hospital:data.rows[0].key[2],city:data.rows[0].key[3],price:data.rows[0].key[1].toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")}
				$("#lowRow #{clas}").html(template.extreams(min))
		
			$.ajax(
				url:url
				data:
					startkey:if state then "[\"#{key}\",\"#{state}\"]" else "[\"#{key}\"]" 
					limit:1
					skip:count-1
					reduce:false
				dataType : "jsonp"
			).then (data)->
				if state
					max = {direction:'Most Expensive',highlight:'error',state:data.rows[0].key[1],hospital:data.rows[0].key[3],city:data.rows[0].key[4],price:data.rows[0].key[2].toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")}
				else
					max = {direction:'Most Expensive',highlight:'error',state:data.rows[0].key[4],hospital:data.rows[0].key[2],city:data.rows[0].key[3],price:data.rows[0].key[1].toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")}
				$("#highRow #{clas}").html(template.extreams(max))
bottom = makeView("Average Total Payment",urlBase,urlBaseState,'.tot')
side = makeView("Average Covered Cost",otherBase,otherBaseState,'.covered')
$.ajax(
	url:urlBase
	data:
		group_level:1
	dataType : "jsonp"
).then (data)->
	out={}
	out.rows = for row in data.rows
		do (row)->
			ret = row.value
			ret.name = row.key[0]
			ret
	$('#totselect').html(template.selectorist(out))
	$('#totselect').on 'change', bottom
	$('#totselect').on 'change', side
	true
$.ajax(
	url:stateUrl
	data:
		group:true
	dataType:'jsonp'
).then (data)->
	$("#stateSelect").html(template.states(data))
	$("#stateSelect").on "change",()->
		side()
		bottom()