import Foundation
import FamilyControls

/// Device-local configuration slots. Anonymous Family Controls tokens never leave App Group.
struct BaraPreset: Codable, Identifiable {
    let id: UUID
    var name: String
    var dailyMinutes: Int
    var selectionData: Data?
    // Optional for forwards-compatible migration of earlier locally saved profiles.
    var language: String? = nil
    var theme: String? = nil
}

enum ProfileLibrary {
    static let maxProfiles=8
    private static let allKey="profileSlotsV1"
    private static let currentKey="activeProfileV1"

    static func all()->[BaraPreset] {
        if let data=SharedConfig.groupDefaults?.data(forKey:allKey),
           let decoded=try? JSONDecoder().decode([BaraPreset].self,from:data),
           !decoded.isEmpty, decoded.count<=maxProfiles {
            return decoded
        }
        let original=BaraPreset(
            id:UUID(),name:"默认",
            dailyMinutes:max(1,min(240,SharedConfig.defaults.integer(forKey:SharedConfig.limitKey)==0
                ? 20 : SharedConfig.defaults.integer(forKey:SharedConfig.limitKey))),
            selectionData:SharedConfig.defaults.data(forKey:SharedConfig.selectionKey),
            language:SharedConfig.defaults.string(forKey:"language") ?? "system",
            theme:SharedConfig.defaults.string(forKey:"theme") ?? "system")
        persist([original],active:original.id)
        return [original]
    }

    static func activeID()->UUID {
        let slots=all()
        if let stored=SharedConfig.groupDefaults?.string(forKey:currentKey),
           let parsed=UUID(uuidString:stored),slots.contains(where:{$0.id==parsed}) {
            return parsed
        }
        return slots[0].id
    }

    static func current()->BaraPreset {
        all().first(where:{$0.id==activeID()}) ?? all()[0]
    }
    static func named(_ id:UUID)->BaraPreset? { all().first(where:{$0.id==id}) }

    @discardableResult static func persist(_ items:[BaraPreset],active:UUID)->Bool {
        guard !items.isEmpty,items.count<=maxProfiles,
              items.contains(where:{$0.id==active}),
              let data=try? JSONEncoder().encode(items),
              let defaults=SharedConfig.groupDefaults else { return false }
        defaults.set(data,forKey:allKey)
        defaults.set(active.uuidString,forKey:currentKey)
        return true
    }

    static func saveCurrent(selection:FamilyActivitySelection,minutes:Int)->Bool {
        var items=all()
        guard let index=items.firstIndex(where:{$0.id==activeID()}),
              let data=try? JSONEncoder().encode(selection) else { return false }
        items[index].selectionData=data
        items[index].dailyMinutes=max(1,min(240,minutes))
        items[index].language=SharedConfig.defaults.string(forKey:"language") ?? "system"
        items[index].theme=SharedConfig.defaults.string(forKey:"theme") ?? "system"
        return persist(items,active:items[index].id)
    }

    static func create(name:String,duplicate:Bool)->Bool {
        let trimmed=String(name.trimmingCharacters(in:.whitespacesAndNewlines).prefix(24))
        var items=all()
        guard !trimmed.isEmpty,items.count<maxProfiles else { return false }
        let old=current()
        let record=BaraPreset(id:UUID(),name:trimmed,
                              dailyMinutes:duplicate ? old.dailyMinutes : 20,
                              selectionData:duplicate ? old.selectionData : nil,
                              language:old.language,theme:old.theme)
        items.append(record)
        return persist(items,active:activeID())
    }

    static func rename(_ id:UUID,to name:String)->Bool {
        let trimmed=String(name.trimmingCharacters(in:.whitespacesAndNewlines).prefix(24))
        var items=all()
        guard !trimmed.isEmpty,let i=items.firstIndex(where:{$0.id==id}) else { return false }
        items[i].name=trimmed
        return persist(items,active:activeID())
    }

    static func activate(_ id:UUID)->Bool {
        let items=all()
        return items.contains(where:{$0.id==id}) && persist(items,active:id)
    }

    static func delete(_ id:UUID)->Bool {
        let items=all()
        guard id != activeID(),items.count>1,items.contains(where:{$0.id==id}) else {return false}
        return persist(items.filter {$0.id != id},active:activeID())
    }

    static func decodedSelection(_ profile:BaraPreset)->FamilyActivitySelection {
        guard let data=profile.selectionData,
              let selection=try? JSONDecoder().decode(FamilyActivitySelection.self,from:data)
        else { return FamilyActivitySelection() }
        return selection
    }
}
