extends Object

class_name CRAFT

static func get_craftable_list():
	var allList = DEF.sDefs.keys()
	#allList is every entry in sDefs
	#we need to exclude default, Flags, and any entry with the noncraft flag
	var toExclude = ["Flags","default"]
	var back_idx = -1
	#send all elements to be romved to the end, then truncate array to get list of craftables
	for i in allList.size():
		while allList[i] in toExclude or DEF.EntryHasFlag(DEF.sDefs,allList[i],&"nonCraft"):
			var temp = allList[i]
			allList[i] = allList[back_idx]
			allList[back_idx] = temp
			back_idx -= 1
		if i >= allList.size()+back_idx:
			break
	return allList.slice(0,allList.size()+back_idx+1)
	
static func get_valid_mats(shape:StringName,mob:Mob):
	var reqFlag = 0
	#if shape needs shapeable material, material must have isShapeable flag
	reqFlag |= int(DEF.mDefs[&"Flags"][&"isShapeable"]) if DEF.EntryHasFlag(DEF.sDefs, shape,&"needsShapeable") else 0
	#if shape is soft, require clothLike
	reqFlag |= int(DEF.mDefs[&"Flags"][&"isCloth"]) if DEF.EntryHasFlag(DEF.sDefs,shape,&"isSoft") else 0
	
	var cantFlag = 0
	#if shape isn't soft, cant use clothLike
	cantFlag |=  int(DEF.mDefs[&"Flags"][&"isCloth"]) if not DEF.EntryHasFlag(DEF.sDefs, shape, &"isSoft") else 0
	var mob_mats = []
	var mat_counts = {}
	for i in mob.get_access_items():
		if reqFlag & DEF.mDefs[i.mat][&"flags"] != reqFlag or cantFlag & DEF.mDefs[i.mat][&"flags"] or DEF.getProperty(DEF.sDefs,i.shape,&"m_count") is Array or i.shape==shape:
				continue;
		if not mat_counts.has(i.mat):
			mat_counts[i.mat] = 0
		mat_counts[i.mat] += i.volume
	for i in mat_counts:
		if mat_counts[i]>=DEF.getProperty(DEF.sDefs,shape,&"m_count"):
			mob_mats.append(i)
	return mob_mats

static func get_recipie(shape:StringName,mob:Mob):
	if DEF.EntryHasFlag(DEF.sDefs,shape,&"nonCraft"):
		return null
	var recipie = {}
	var itemIng = DEF.getProperty(DEF.sDefs,shape,&"m_count")
	if typeof(itemIng)!=TYPE_ARRAY:
		#recipie is just raw material->shape
		recipie["Count"] = DEF.dispLiter(itemIng)
		recipie["Materials"] = get_valid_mats(shape,mob)
	else:
		#recipie is shapes->new shape
		recipie ["Items"] = itemIng
	return recipie
