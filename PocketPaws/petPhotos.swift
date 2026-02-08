import SwiftUI
import PhotosUI
import UIKit

private struct GatewayPhoto: Decodable, Identifiable {
    let id: String
    let fileName: String
    let caption: String
    let date: String
    let objectUrl: String
    let isFavorite: Bool?
}

private struct GatewayPhotosResponse: Decodable {
    let photos: [GatewayPhoto]
}

private struct GatewayUploadPhotoRequest: Encodable {
    let petId: String?
    let fileName: String
    let mimeType: String
    let base64Data: String
    let caption: String
    let date: String
}

private struct GatewayUploadPhotoResponse: Decodable {
    let photo: GatewayPhoto?
}

struct PetPhotosView: View {
    @EnvironmentObject var router: Router
    @State private var isShowingPhotoPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var capturedImages: [UIImage] = []
    @State private var remotePhotos: [GatewayPhoto] = []
    @State private var pickerError: String?
    @State private var isLoadingPhotos = false
    @State private var isUploading = false

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            PetPalBackground()

            VStack(spacing: 0) {
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left").foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    Text("Photo Gallery").font(DesignTokens.Typography.headline)
                    Spacer()
                    CircularIconButton(icon: "camera.fill") {
                        isShowingPhotoPicker = true
                    }
                }
                .padding()

                ScrollView {
                    if isLoadingPhotos {
                        Text("Loading photos...")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .padding(.horizontal)
                    }

                    if isUploading {
                        Text("Uploading selected photos...")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .padding(.horizontal)
                    }

                    if !capturedImages.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                            Text("New Captures")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(capturedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                        .aspectRatio(1, contentMode: .fill)
                                        .cornerRadius(DesignTokens.Radius.m)
                                        .clipped()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, DesignTokens.Spacing.s)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if remotePhotos.isEmpty && !isLoadingPhotos {
                        Text("No uploaded photos yet. Add one with the camera button.")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .padding(.horizontal)
                            .padding(.top, DesignTokens.Spacing.s)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(remotePhotos) { photo in
                            AsyncImage(url: URL(string: photo.objectUrl)) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                            .cornerRadius(DesignTokens.Radius.m)
                            .clipped()
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.m)
                                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: (photo.isFavorite ?? false) ? "heart.fill" : "heart")
                                    .foregroundColor((photo.isFavorite ?? false) ? .pink : .white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.2))
                                    .clipShape(Circle())
                                    .padding(8),
                                alignment: .bottomTrailing
                            )
                        }
                    }
                    .padding()
                }

                BottomNavBar(selectedTab: $router.currentTab) { screen in
                    router.switchTab(to: screen)
                }
            }
        }
        .photosPicker(isPresented: $isShowingPhotoPicker, selection: $selectedPhotoItems, maxSelectionCount: 0, matching: .images)
        .task {
            await loadPhotos()
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                await uploadSelectedItems(newItems)
            }
        }
        .alert("Photos", isPresented: Binding(
            get: { pickerError != nil },
            set: { show in
                if !show { pickerError = nil }
            }
        )) {
            Button("OK", role: .cancel) { pickerError = nil }
        } message: {
            Text(pickerError ?? "")
        }
        .navigationBarHidden(true)
    }

    private func loadPhotos() async {
        guard router.isAuthenticated else {
            pickerError = "Please sign in before loading photos."
            return
        }

        isLoadingPhotos = true
        defer { isLoadingPhotos = false }

        do {
            var request = URLRequest(url: router.gatewayURL(path: "photos"))
            request.httpMethod = "GET"
            for (header, value) in router.gatewayAuthHeaders() {
                request.setValue(value, forHTTPHeaderField: header)
            }

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            guard (200..<300).contains(http.statusCode) else {
                throw NSError(
                    domain: "PetPhotos",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: decodeErrorMessage(data: data, statusCode: http.statusCode)]
                )
            }

            let payload = try JSONDecoder().decode(GatewayPhotosResponse.self, from: data)
            remotePhotos = payload.photos
        } catch {
            pickerError = error.localizedDescription
        }
    }

    private func uploadSelectedItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        guard router.isAuthenticated else {
            pickerError = "Please sign in before uploading photos."
            return
        }

        isUploading = true
        defer {
            isUploading = false
            selectedPhotoItems = []
        }

        for newItem in items {
            do {
                guard let data = try await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data),
                      let jpegData = image.jpegData(compressionQuality: 0.9)
                else {
                    throw NSError(
                        domain: "PetPhotos",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Could not read one of the selected images."]
                    )
                }

                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    capturedImages.append(image)
                }

                let uploadedPhoto = try await uploadPhoto(jpegData: jpegData)
                withAnimation(.easeOut(duration: 0.2)) {
                    remotePhotos.insert(uploadedPhoto, at: 0)
                }
            } catch {
                pickerError = error.localizedDescription
            }
        }
    }

    private func uploadPhoto(jpegData: Data) async throws -> GatewayPhoto {
        let dateStamp = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let fileName = "ios-\(UUID().uuidString).jpg"

        let requestBody = GatewayUploadPhotoRequest(
            petId: nil,
            fileName: fileName,
            mimeType: "image/jpeg",
            base64Data: jpegData.base64EncodedString(),
            caption: "Uploaded from iOS",
            date: String(dateStamp)
        )

        var request = URLRequest(url: router.gatewayURL(path: "photos/upload"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (header, value) in router.gatewayAuthHeaders() {
            request.setValue(value, forHTTPHeaderField: header)
        }
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NSError(
                domain: "PetPhotos",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: decodeErrorMessage(data: data, statusCode: http.statusCode)]
            )
        }

        let payload = try JSONDecoder().decode(GatewayUploadPhotoResponse.self, from: data)
        guard let photo = payload.photo else {
            throw NSError(
                domain: "PetPhotos",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Upload succeeded but no photo payload was returned."]
            )
        }
        return photo
    }

    private func decodeErrorMessage(data: Data, statusCode: Int) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Photo request failed (\(statusCode))."
        }

        if let errorText = object["error"] as? String,
           !errorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return errorText
        }

        if let errorObj = object["error"] as? [String: Any] {
            if let message = errorObj["message"] as? String,
               !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return message
            }
            if let code = errorObj["code"] as? String,
               !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return code
            }
        }

        return "Photo request failed (\(statusCode))."
    }
}

struct PetPhotosView_Preview: PreviewProvider {
    static var previews: some View {
        PetPhotosView().environmentObject(Router())
    }
}
