//
//  mqtt_manager.swift
//  mqtt_test
//
//  Created by Filip Juchnowicz on 21/10/2024.
//

import Foundation
import CocoaMQTT


class IoTManager_old {
    var mqtt: CocoaMQTT5!
    
    func connectToBroker() -> Bool {
        let clientID = "xcode_dev"
        let host = "f58a72c5a6fc46ac93cefed6916f36a7.s1.eu.hivemq.cloud"
//        let host = "broker.emqx.io"
//        let host = "broker.hivemq.com"
        let port: UInt16 = 8883
//        let port: UInt16 = 1883
        
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
        mqtt.username = "Morfinix"
        mqtt.password = "BrunoPL23"
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

        print("Connecting...")
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

extension IoTManager_old: CocoaMQTT5Delegate {
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
