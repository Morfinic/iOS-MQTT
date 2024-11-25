//
//  mqtt_testApp.swift
//  mqtt_test
//
//  Created by Filip Juchnowicz on 21/10/2024.
//

import SwiftUI
import CocoaMQTT

class Payload: ObservableObject {
    static let shared = Payload()
    @Published var arr: [String] = []
    private init(){}
    
    func get() -> [String] {
        return arr
    }
    
    func add(_ val: String) {
        arr.append(val)
    }
}

class IoTManager {
    var mqtt: CocoaMQTT5!
    
    func connectToBroker() -> Bool {
        let clientID = "xcode_dev"
        let host = ""
        let port: UInt16 = 8883
        
        mqtt = CocoaMQTT5(
            clientID: clientID,
            host: host,
            port: port
        )
        
        let connectProperties = MqttConnectProperties()
        connectProperties.topicAliasMaximum = 0
        connectProperties.sessionExpiryInterval = 0
        connectProperties.receiveMaximum = 100
        connectProperties.maximumPacketSize = 500
        mqtt.connectProperties = connectProperties
        
//        mqtt.logLevel = .debug
        mqtt.username = ""
        mqtt.password = ""
        mqtt.keepAlive = UInt16(60)
        mqtt.delegate = self
        mqtt.backgroundOnSocket = true
        mqtt.autoReconnect = true
        
        mqtt.enableSSL = true
        mqtt.allowUntrustCACertificate = true
        
        let ssl_settings: [String: NSObject] = [
            kCFStreamSSLPeerName as String: host as NSString,
            kCFStreamSSLIsServer as String: false as NSNumber
        ]
        mqtt.sslSettings = ssl_settings

        return mqtt.connect()
    }
    
    func subscribeToTopic(topic: String) {
        mqtt.subscribe(topic)
    }
    
    func publish(topic: String, with message: String) {
        let prop = MqttPublishProperties()
        
        prop.contentType = String()
        
        mqtt.publish(topic, withString: message, qos: .qos2, properties: prop)
    }
}

extension IoTManager: CocoaMQTT5Delegate {
    func mqtt5(_ mqtt5: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData: MqttDecodeConnAck?) {
        if ack == .success {
            print("Connected to broker")
            publish(topic: "xcode/init", with: "xcode init")
            subscribeToTopic(topic: "esp_ms/s1")
        } else {
            print("Failed to connect to broker")
        }
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {
        print("Data published succesfully")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) {
        print("Publish ack")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) {
        print("Publish rec")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish?) {
        if let messageString = message.string {
            print("Received message on topic \(message.topic): \(messageString)")
            
            switch message.topic {
            case "esp_ms/s1":
                let date = DateFormatter()
                date.dateFormat = "HH:mm:ss E, d MMM y"
                
                Payload.shared.add(messageString + ", " + date.string(from: Date.now))
            default:
                print("Topic not found")
            }
        }
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData: MqttDecodeSubAck?) {
          print("Sub topic \(success)")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didUnsubscribeTopics topics: [String], unsubAckData: MqttDecodeUnsubAck?) {
        print("Unsub topic \(topics)")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode) {
        print("DC reason code: \(reasonCode)")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
        print("Auth reason: \(reasonCode)")
    }
    
    func mqtt5DidPing(_ mqtt5: CocoaMQTT5) {
        print("Ping")
    }
    
    func mqtt5DidReceivePong(_ mqtt5: CocoaMQTT5) {
        print("Pong")
    }
    
    func mqtt5DidDisconnect(_ mqtt5: CocoaMQTT5, withError err: (any Error)?) {
        print("Disconnected, error: \(err.debugDescription)")
    }
    
    func mqtt5(_ mqtt: CocoaMQTT5, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}


@main
struct mqtt_testApp: App {
    let iotManager = IoTManager()
    @ObservedObject private var payload: Payload = Payload.shared
    
    init() {
        if iotManager.connectToBroker(){
            print("IotManager created")
        }
        else{
            print("Failed to create IoTManager")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color(.lightGray))
                        .frame(width: UIScreen.main.bounds.width, height: 50)
                    Text("Motion sensor")
                        .font(.system(size: 36))
                }
                
                List {
                    ForEach(payload.get(), id: \.self) { entry in
                        Text(entry)
                    }
                }
                .contentMargins(10)
                
                Button("Debug button"){
                    iotManager.publish(topic: "esp_ms/s1", with: "Esp8266 ms1 detected motion")
                }
                .font(.system(size: 24))
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
