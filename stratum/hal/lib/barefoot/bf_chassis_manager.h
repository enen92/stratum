// Copyright 2018-present Barefoot Networks, Inc.
// SPDX-License-Identifier: Apache-2.0

#ifndef STRATUM_HAL_LIB_BAREFOOT_BF_CHASSIS_MANAGER_H_
#define STRATUM_HAL_LIB_BAREFOOT_BF_CHASSIS_MANAGER_H_

#include <map>
#include <memory>
#include <thread>  // NOLINT

#include "absl/base/thread_annotations.h"
#include "absl/memory/memory.h"
#include "absl/synchronization/mutex.h"
#include "absl/types/optional.h"
#include "stratum/glue/integral_types.h"
#include "stratum/hal/lib/barefoot/bf_sde_interface.h"
#include "stratum/hal/lib/common/gnmi_events.h"
#include "stratum/hal/lib/common/phal_interface.h"
#include "stratum/hal/lib/common/utils.h"
#include "stratum/hal/lib/common/writer_interface.h"
#include "stratum/lib/channel/channel.h"

namespace stratum {
namespace hal {
namespace barefoot {

// Lock which protects chassis state across the entire switch.
extern absl::Mutex chassis_lock;

class BFChassisManager {
 public:
  virtual ~BFChassisManager();

  virtual ::util::Status PushChassisConfig(const ChassisConfig& config)
      EXCLUSIVE_LOCKS_REQUIRED(chassis_lock);

  virtual ::util::Status VerifyChassisConfig(const ChassisConfig& config)
      SHARED_LOCKS_REQUIRED(chassis_lock);

  virtual ::util::Status Shutdown() LOCKS_EXCLUDED(chassis_lock);

  virtual ::util::Status RegisterEventNotifyWriter(
      const std::shared_ptr<WriterInterface<GnmiEventPtr>>& writer)
      LOCKS_EXCLUDED(gnmi_event_lock_);

  virtual ::util::Status UnregisterEventNotifyWriter()
      LOCKS_EXCLUDED(gnmi_event_lock_);

  virtual ::util::StatusOr<DataResponse> GetPortData(
      const DataRequest::Request& request) SHARED_LOCKS_REQUIRED(chassis_lock);

  virtual ::util::StatusOr<PortState> GetPortState(uint64 node_id,
                                                   uint32 port_id)
      SHARED_LOCKS_REQUIRED(chassis_lock);

  virtual ::util::Status GetPortCounters(uint64 node_id, uint32 port_id,
                                         PortCounters* counters)
      SHARED_LOCKS_REQUIRED(chassis_lock);

  virtual ::util::Status ReplayPortsConfig(uint64 node_id)
      EXCLUSIVE_LOCKS_REQUIRED(chassis_lock);

  virtual ::util::Status ResetPortsConfig(uint64 node_id)
      EXCLUSIVE_LOCKS_REQUIRED(chassis_lock);

  virtual ::util::Status GetFrontPanelPortInfo(uint64 node_id, uint32 port_id,
                                               FrontPanelPortInfo* fp_port_info)
      SHARED_LOCKS_REQUIRED(chassis_lock);

  ::util::StatusOr<std::map<uint64, int>> GetNodeIdToUnitMap() const
      SHARED_LOCKS_REQUIRED(chassis_lock);

  ::util::StatusOr<int> GetUnitFromNodeId(uint64 node_id) const
      SHARED_LOCKS_REQUIRED(chassis_lock);

  virtual ::util::StatusOr<uint32> GetSdkPortId(uint64 node_id,
                                                uint32 port_id) const
      SHARED_LOCKS_REQUIRED(chassis_lock);

  // Factory function for creating the instance of the class.
  static std::unique_ptr<BFChassisManager> CreateInstance(
      OperationMode mode, PhalInterface* phal_interface,
      BfSdeInterface* bf_sde_interface);

  // BFChassisManager is neither copyable nor movable.
  BFChassisManager(const BFChassisManager&) = delete;
  BFChassisManager& operator=(const BFChassisManager&) = delete;
  BFChassisManager(BFChassisManager&&) = delete;
  BFChassisManager& operator=(BFChassisManager&&) = delete;

 private:
  // Private constructor. Use CreateInstance() to create an instance of this
  // class.
  BFChassisManager(OperationMode mode, PhalInterface* phal_interface,
                   BfSdeInterface* bf_sde_interface);

  // Maximum depth of port status change event channel.
  static constexpr int kMaxPortStatusEventDepth = 1024;
  static constexpr int kMaxXcvrEventDepth = 1024;

  struct PortConfig {
    // ADMIN_STATE_UNKNOWN indicate that something went wrong during the port
    // configuration, and the port add wasn't event attempted or failed.
    AdminState admin_state;
    absl::optional<uint64> speed_bps;  // empty if port add failed
    absl::optional<int32> mtu;         // empty if MTU configuration failed
    absl::optional<TriState> autoneg;  // empty if Autoneg configuration failed
    absl::optional<FecMode> fec_mode;  // empty if port add failed
    // empty if loopback mode configuration failed
    absl::optional<LoopbackState> loopback_mode;
    // empty if no shaping config given
    absl::optional<TofinoConfig::BfPortShapingConfig::BfPerPortShapingConfig>
        shaping_config;

    PortConfig() : admin_state(ADMIN_STATE_UNKNOWN) {}
  };

  ::util::StatusOr<const PortConfig*> GetPortConfig(uint64 node_id,
                                                    uint32 port_id) const
      SHARED_LOCKS_REQUIRED(chassis_lock);

  ::util::Status RegisterEventWriters() EXCLUSIVE_LOCKS_REQUIRED(chassis_lock);
  ::util::Status UnregisterEventWriters() LOCKS_EXCLUDED(chassis_lock);

  // Cleans up the internal state. Resets all the internal port maps and
  // deletes the pointers.
  void CleanupInternalState() EXCLUSIVE_LOCKS_REQUIRED(chassis_lock);

  // Forward PortStatus changed events through the appropriate node's registered
  // ChannelWriter<GnmiEventPtr> object.
  void SendPortOperStateGnmiEvent(uint64 node_id, uint32 port_id,
                                  PortState new_state)
      LOCKS_EXCLUDED(gnmi_event_lock_);

  // Thread function for reading and processing port state events.
  void ReadPortStatusEvents() LOCKS_EXCLUDED(chassis_lock);

  // Thread function for reading and processing transceiver events.
  void ReadTransceiverEvents() LOCKS_EXCLUDED(chassis_lock);

  // Transceiver module insert/removal event handler. This method is executed by
  // ReadTransceiverEvents in the xcvr_event_thread_ thread which processes
  // transceiver module insert/removal events. Port is the 1-based frontpanel
  // port number.
  void TransceiverEventHandler(int slot, int port, HwState new_state)
      LOCKS_EXCLUDED(chassis_lock);

  // helper to add / configure / enable a port with BfSdeInterface
  ::util::Status AddPortHelper(uint64 node_id, int unit, uint32 port_id,
                               const SingletonPort& singleton_port,
                               PortConfig* config);

  // helper to update port configuration with BfSdeInterface
  ::util::Status UpdatePortHelper(uint64 node_id, int unit, uint32 port_id,
                                  const SingletonPort& singleton_port,
                                  const PortConfig& config_old,
                                  PortConfig* config);

  // Helper to apply a port shaping config to a single port.
  ::util::Status ApplyPortShapingConfig(
      uint64 node_id, int unit, uint32 sdk_port_id,
      const TofinoConfig::BfPortShapingConfig::BfPerPortShapingConfig&
          shaping_config);

  // Determines the mode of operation:
  // - OPERATION_MODE_STANDALONE: when Stratum stack runs independently and
  // therefore needs to do all the SDK initialization itself.
  // - OPERATION_MODE_COUPLED: when Stratum stack runs as part of Sandcastle
  // stack, coupled with the rest of stack processes.
  // - OPERATION_MODE_SIM: when Stratum stack runs in simulation mode.
  // Note that this variable is set upon initialization and is never changed
  // afterwards.
  OperationMode mode_;

  bool initialized_ GUARDED_BY(chassis_lock);

  std::shared_ptr<Channel<BfSdeInterface::PortStatusEvent>>
      port_status_event_channel_ GUARDED_BY(chassis_lock);

  std::unique_ptr<ChannelReader<BfSdeInterface::PortStatusEvent>>
      port_status_event_reader_;

  std::thread port_status_event_thread_;

  // The id of the transceiver module insert/removal event ChannelWriter, as
  // returned by PhalInterface::RegisterTransceiverEventChannelWriter(). Used to
  // remove the handler later if needed.
  int xcvr_event_writer_id_;

  std::shared_ptr<Channel<PhalInterface::TransceiverEvent>> xcvr_event_channel_
      GUARDED_BY(chassis_lock);

  std::unique_ptr<ChannelReader<PhalInterface::TransceiverEvent>>
      xcvr_event_reader_;

  std::thread xcvr_event_thread_;

  // WriterInterface<GnmiEventPtr> object for sending event notifications.
  mutable absl::Mutex gnmi_event_lock_;
  std::shared_ptr<WriterInterface<GnmiEventPtr>> gnmi_event_writer_
      GUARDED_BY(gnmi_event_lock_);

  // Map from unit number to the node ID as specified by the config.
  std::map<int, uint64> unit_to_node_id_ GUARDED_BY(chassis_lock);

  // Map from node ID to unit number.
  std::map<uint64, int> node_id_to_unit_ GUARDED_BY(chassis_lock);

  // Map from node ID to another map from port ID to PortState representing
  // the state of the singleton port uniquely identified by (node ID, port ID).
  std::map<uint64, std::map<uint32, PortState>>
      node_id_to_port_id_to_port_state_ GUARDED_BY(chassis_lock);

  // Map from node ID to another map from port ID to port configuration.
  // We may change this once missing "get" methods get added to BfSdeInterface,
  // as we would be able to rely on BfSdeInterface to query config parameters,
  // instead of maintaining a "consistent" view in this map.
  std::map<uint64, std::map<uint32, PortConfig>>
      node_id_to_port_id_to_port_config_ GUARDED_BY(chassis_lock);

  // Map from node ID to another map from port ID to PortKey corresponding
  // to the singleton port uniquely identified by (node ID, port ID). This map
  // is updated as part of each config push.
  std::map<uint64, std::map<uint32, PortKey>>
      node_id_to_port_id_to_singleton_port_key_ GUARDED_BY(chassis_lock);

  // Map from node ID to another map from (SDN) port ID to SDK port ID.
  // SDN port IDs are used in Stratum and by callers to P4Runtime and gNMI,
  // and SDK port IDs are used in calls to the BF SDK. This map is updated
  // as part of each config push.
  std::map<uint64, std::map<uint32, uint32>> node_id_to_port_id_to_sdk_port_id_
      GUARDED_BY(chassis_lock);

  // Map from node ID to another map from SDK port ID to (SDN) port ID.
  // This contains the inverse mapping of: node_id_to_port_id_to_sdk_port_id_
  // This map is updated as part of each config push.
  std::map<uint64, std::map<uint32, uint32>> node_id_to_sdk_port_id_to_port_id_
      GUARDED_BY(chassis_lock);

  // Map from node ID to deflect-on-drop configuration.
  std::map<uint64, TofinoConfig::DeflectOnPacketDropConfig>
      node_id_to_deflect_on_drop_config_ GUARDED_BY(chassis_lock);

  // Map from PortKey representing (slot, port) of a transceiver port to the
  // state of the transceiver module plugged into that (slot, port).
  std::map<PortKey, HwState> xcvr_port_key_to_xcvr_state_
      GUARDED_BY(chassis_lock);

  // Pointer to a PhalInterface implementation.
  PhalInterface* phal_interface_;  // not owned by this class.

  // Pointer to a BfSdeInterface implementation that wraps all the SDE calls.
  BfSdeInterface* bf_sde_interface_;  // not owned by this class.

  friend class BFChassisManagerTest;
};

}  // namespace barefoot
}  // namespace hal
}  // namespace stratum

#endif  // STRATUM_HAL_LIB_BAREFOOT_BF_CHASSIS_MANAGER_H_
